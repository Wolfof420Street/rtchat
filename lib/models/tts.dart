import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts/bytes_audio_source.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/user.dart';

enum TtsMode { disabled, alertsOnly, enabled }

class TtsModel extends ChangeNotifier {
  var _isCloudTtsEnabled = false;
  final _tts = FlutterTts()
    ..setSharedInstance(true)
    ..setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        IosTextToSpeechAudioMode.voicePrompt);

  final audioPlayer = AudioPlayer();
  Future<void> _previousUtterance = Future.value();
  final Set<String> _pending = {};
  var _language = Language();
  List<String> voices = [];
  final Map<String, dynamic> _voice = {};
  var _isSupportedLanguage = false;
  var _isRandomVoiceEnabled = true;
  var _isBotMuted = false;
  var _isEmoteMuted = false;
  var _isPreludeMuted = false;
  var _speed = Platform.isAndroid ? 0.8 : 0.395;
  var _pitch = 1.0;
  var _mode = TtsMode.disabled;
  var _isNewTTsEnabled = false;
  final Set<TwitchUserModel> _mutedUsers = {};
  // this is used to ignore messages in the past.
  var _lastMessageTime = DateTime.now();
  MessageModel? _activeMessage;
  var _isSubscribersOnly = false;

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  void update(UserModel model) async {
    if (kDebugMode) {
      final channel = model.activeChannel;
      if (channel == null) {
        _isSupportedLanguage = false;
        _language = Language();
        return;
      }

      String? streamLanguage =
          await ChannelsAdapter.instance.forChannel(channel).map((event) {
        if (event is TwitchChannelMetadata) {
          return event.language;
        }
        throw "invalid provider";
      }).first;
      if (streamLanguage == null) {
        _isSupportedLanguage = false;
        _language = Language();
        return;
      }

      _isSupportedLanguage =
          !(streamLanguage == 'other' || streamLanguage == 'asl');
      language = _isSupportedLanguage ? Language(streamLanguage) : Language();
      notifyListeners();
    }
  }

  void getVoices() async {
    if (!isCloudTtsEnabled) {
      return;
    }
    final voicesJson = await FirebaseFunctions.instance
        .httpsCallable("getVoices")
        .call(<String, dynamic>{
      "language": _language.languageCode,
    });
    final data = voicesJson.data;

    final List<String> voicesList = [];
    for (LinkedHashMap voice in data) {
      voicesList.add(voice['name']);
    }
    voices = voicesList;
    if (_voice[language.languageCode] == null) {
      voice = voicesList[0];
    }
    notifyListeners();
  }

  String getVocalization(AppLocalizations l10n, MessageModel model,
      {bool includeAuthorPrelude = false}) {
    if (model is TwitchMessageModel) {
      final text = model.tokenized
          .where((token) =>
              token is TextToken ||
              (!_isEmoteMuted && token is EmoteToken) ||
              token is UserMentionToken ||
              token is LinkToken)
          .map((token) {
        if (token is TextToken) {
          return token.text;
        } else if (token is EmoteToken) {
          return token.code;
        } else if (token is UserMentionToken) {
          return token.username.replaceAll("_", " ");
        } else if (token is LinkToken) {
          return token.url.host;
        }
      }).join("");
      if (text.trim().isEmpty) {
        return "";
      }
      final author = model.author.displayName ?? model.author.login;
      if (!includeAuthorPrelude || isPreludeMuted) {
        return text;
      }
      return model.isAction
          ? l10n.actionMessage(author, text)
          : l10n.saidMessage(author, text);
    } else if (model is StreamStateEventModel) {
      final timestamp = model.timestamp;
      return model.isOnline
          ? l10n.streamOnline(timestamp, timestamp)
          : l10n.streamOffline(timestamp, timestamp);
    } else if (model is SystemMessageModel) {
      return model.text;
    } else if (model is TwitchRaidEventModel) {
      return l10n.raidEventMessage(model.from.displayName ?? "", model.viewers);
    } else if (model is TwitchSubscriptionEventModel) {
      return l10n.subscriptionEvent(
          model.subscriberUserName, model.tier.replaceAll("000", ""));
    } else if (model is TwitchSubscriptionGiftEventModel) {
      return l10n.subscriptionGiftEvent(model.gifterUserName, model.total,
          model.tier.replaceAll("000", ""), model.cumulativeTotal);
    } else if (model is TwitchSubscriptionMessageEventModel) {
      return l10n.subscriptionMessageEvent(
        model.subscriberUserName,
        model.cumulativeMonths,
        model.tier.replaceAll("000", ""),
      );
    } else if (model is TwitchFollowEventModel) {
      return l10n.followingEvent(
          model.followers.first.displayName ?? model.followers.first.login);
    } else if (model is TwitchCheerEventModel) {
    } else if (model is TwitchPollEventModel) {
    } else if (model is TwitchChannelPointRedemptionEventModel) {
    } else if (model is TwitchHypeTrainEventModel) {
    } else if (model is TwitchPredictionEventModel) {
    } else if (model is TwitchHostEventModel) {
    } else if (model is TwitchRaidingEventModel) {
    } else if (model is ChatClearedEventModel) {
    } else if (model is StreamlabsDonationEventModel) {
    } else if (model is StreamElementsTipEventModel) {
    } else if (model is SimpleRealtimeCashDonationEventModel) {
    } else if (model is TwitchShoutoutCreateEventModel) {
    } else if (model is TwitchShoutoutReceiveEventModel) {}
    return "";
  }

  bool get newTtsEnabled {
    return _isNewTTsEnabled;
  }

  bool get isSubscribersOnly {
    return _isSubscribersOnly;
  }

  set isSubscribersOnly(bool value) {
    _isSubscribersOnly = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  set newTtsEnabled(bool value) {
    if (value == _isNewTTsEnabled) {
      return;
    }
    _isNewTTsEnabled = value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  TtsMode get mode {
    return _mode;
  }

  void toggleMode(AppLocalizations localizations) {
    switch (_mode) {
      case TtsMode.disabled:
        setMode(localizations, TtsMode.enabled); // TODO: enable alerts tts
        break;
      case TtsMode.alertsOnly:
        setMode(localizations, TtsMode.enabled);
        break;
      case TtsMode.enabled:
        setMode(localizations, TtsMode.disabled);
        break;
    }
  }

  void setMode(AppLocalizations localizations, TtsMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    switch (mode) {
      case TtsMode.alertsOnly:
        say(localizations,
            SystemMessageModel(text: localizations.alertsEnabled),
            force: true);
        break;
      case TtsMode.enabled:
        say(localizations,
            SystemMessageModel(text: localizations.textToSpeechEnabled),
            force: true);
        break;
      case TtsMode.disabled:
        say(localizations,
            SystemMessageModel(text: localizations.textToSpeechDisabled),
            force: true);
        break;
    }
    _lastMessageTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Language get language {
    return _language;
  }

  set language(Language language) {
    _language = language;
    getVoices();
    notifyListeners();
  }

  bool get isSupportedLanguage {
    return _isSupportedLanguage;
  }

  set isSupportedLanguage(bool isSupportedLanguage) {
    _isSupportedLanguage = isSupportedLanguage;
    notifyListeners();
  }

  String get voice {
    return _voice[_language.languageCode] ?? voices[0];
  }

  set voice(String voice) {
    _voice[_language.languageCode] = voice;
    notifyListeners();
  }

  bool get isRandomVoiceEnabled {
    return _isRandomVoiceEnabled;
  }

  set isRandomVoiceEnabled(bool value) {
    _isRandomVoiceEnabled = value;
    notifyListeners();
  }

  bool get isBotMuted {
    return _isBotMuted;
  }

  set isBotMuted(bool value) {
    _isBotMuted = value;
    notifyListeners();
  }

  bool get isEmoteMuted {
    return _isEmoteMuted;
  }

  set isEmoteMuted(bool value) {
    _isEmoteMuted = value;
    notifyListeners();
  }

  bool get isPreludeMuted {
    return _isPreludeMuted;
  }

  set isPreludeMuted(bool value) {
    _isPreludeMuted = value;
    notifyListeners();
  }

  bool get isCloudTtsEnabled {
    return _isCloudTtsEnabled;
  }

  set isCloudTtsEnabled(bool value) {
    _isCloudTtsEnabled = value;
    if (value) {
      getVoices();
    }
    notifyListeners();
  }

  double get speed {
    return _speed;
  }

  set speed(double value) {
    _speed = value;
    notifyListeners();
  }

  double get pitch {
    return _pitch;
  }

  set pitch(double value) {
    _pitch = value;
    notifyListeners();
  }

  bool isMuted(TwitchUserModel user) {
    return _mutedUsers.contains(user);
  }

  void mute(TwitchUserModel model) {
    _mutedUsers.add(model);
    notifyListeners();
  }

  void unmute(TwitchUserModel model) {
    if (_mutedUsers.remove(model)) {
      notifyListeners();
    }
  }

  void say(AppLocalizations localizations, MessageModel model,
      {bool force = false}) async {
    if (_mode == TtsMode.disabled && !force) {
      return;
    }

    if (_mode == TtsMode.alertsOnly && model is TwitchMessageModel) {
      return;
    }

    if (model is TwitchMessageModel) {
      if (_isSubscribersOnly && (model.tags['badges']?['subscriber'] == null)) {
        return;
      }

      if (_mutedUsers.any((user) =>
          user.displayName?.toLowerCase() ==
          model.author.displayName?.toLowerCase())) {
        return;
      }

      if ((_isBotMuted && model.author.isBot) || model.isCommand) {
        return;
      }
    }

    // make sure the message is in the future.
    if (model is SystemMessageModel) {
      if (model.timestamp.isBefore(_lastMessageTime)) {
        return;
      }
      _lastMessageTime = model.timestamp;
    }

    final activeMessage = _activeMessage;
    var includeAuthorPrelude = true;
    if (activeMessage is TwitchMessageModel && model is TwitchMessageModel) {
      includeAuthorPrelude = !(activeMessage.author == model.author);
    }

    final vocalization = getVocalization(
      localizations,
      model,
      includeAuthorPrelude: includeAuthorPrelude,
    );

    // if the vocalization is empty, skip the message
    if (vocalization.isEmpty) {
      return;
    }

    final previous = _previousUtterance;
    final completer = Completer();

    _previousUtterance = completer.future;
    _pending.add(model.messageId);

    await previous;

    _activeMessage = model;

    if ((_mode != TtsMode.disabled || model is SystemMessageModel) &&
        _pending.contains(model.messageId)) {
      // TODO: replace with subscription logic
      if (!_isCloudTtsEnabled) {
        try {
          await _tts.setSpeechRate(_speed);
          await _tts.setPitch(_pitch);
          await _tts.awaitSpeakCompletion(true);
          await _tts.speak(vocalization);
        } catch (e, st) {
          FirebaseCrashlytics.instance.recordError(e, st);
        }
      } else {
        String? voice;
        double? pitch;
        if (model is TwitchMessageModel) {
          if (isRandomVoiceEnabled) {
            final name = model.author.displayName;
            final hash = name.hashCode;
            voice = voices[hash % voices.length];
            pitch = (hash % 21) / 5 - 2;
          } else {
            voice = _voice[_language.languageCode];
            pitch = _pitch * 4 - 2;
          }
        }
        final response =
            await FirebaseFunctions.instance.httpsCallable("synthesize")({
          "voice": voice ?? "en-US-WaveNet-F",
          "text": vocalization,
          "rate": _speed * 1.5 + 0.5,
          "pitch": pitch ?? 0,
        });
        final bytes = const Base64Decoder().convert(response.data);
        await audioPlayer.setAudioSource(BytesAudioSource(bytes));
        await audioPlayer.play();
        await Future.delayed(audioPlayer.duration ?? const Duration());
      }
    }

    _activeMessage = null;

    completer.complete();
    _pending.remove(model.messageId);
  }

  void unsay(String messageId) {
    _pending.remove(messageId);
  }

  void stop() {
    _pending.clear();
  }

  void updateFromJson(Map<String, dynamic> json) {
    _updateFromJsonInternal(json);
    notifyListeners();
  }

  void _updateFromJsonInternal(Map<String, dynamic> json) {
    if (json['isBotMuted'] != null) {
      _isBotMuted = json['isBotMuted'];
    }
    if (json['pitch'] != null) {
      _pitch = json['pitch'];
    }
    if (json['speed'] != null) {
      _speed = json['speed'];
    }
    if (json['isEmoteMuted'] != null) {
      _isEmoteMuted = json['isEmoteMuted'];
    }
    if (json['isPreludeMuted'] != null) {
      _isPreludeMuted = json['isPreludeMuted'];
    }
    if (json['isRandomVoiceEnabled'] != null) {
      _isRandomVoiceEnabled = json['isRandomVoiceEnabled'];
    }
    if (json['language'] != null) {
      _language = Language(json['language']);
    }
    if (json['voice'] != null) {
      _voice.addAll(json['voice']);
    }
    final userJson = json['mutedUsers'];
    if (userJson != null) {
      for (var user in userJson) {
        _mutedUsers.add(TwitchUserModel.fromJson(user));
      }
    }
  }

  TtsModel.fromJson(Map<String, dynamic> json) {
    _updateFromJsonInternal(json);
  }

  Map<String, dynamic> toJson() => {
        "isBotMuted": isBotMuted,
        "isEmoteMuted": isEmoteMuted,
        "isPreludeMuted": isPreludeMuted,
        "isRandomVoiceEnabled": isRandomVoiceEnabled,
        "language": language.languageCode,
        "pitch": pitch,
        "speed": speed,
        "voice": _voice,
        'mutedUsers': _mutedUsers.map((e) => e.toJson()).toList(),
      };
}
