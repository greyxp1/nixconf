{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.nixcord.nixosModules.nixcord];
  programs.nixcord = {
    enable = true;
    user = "grey";
    useGlobalPkgs = true;
    discord = {
      enable = true;
      equicord.enable = true;
      openASAR.enable = false;
      commandLineArgs = ["--force-prefers-reduced-motion"];
    };
    equicordConfig = {
      useQuickCSS = false;
      notifications.useNative = "never";
      plugins = {
        NoRPC.enabled = true;
        ClientPreferences = {
          desktopNotifications = false;
          notificationSounds = false;
        };
        FakeNitro = {
          enableEmojiBypass = false;
          enableStickerBypass = false;
          transformEmojis = false;
          transformStickers = false;
        };
        Questify = {
          enabled = true;
          migrationVersion = 1;
          acknowledgedNotices = {
            quest-ban-warning-2026-08-07 = true;
            quest-ban-warning-2026-08-26 = true;
          };
          allowChangingDangerousSettings = true;
          autoCompleteQuestTypes = {
            ACHIEVEMENT_IN_ACTIVITY = true;
            PLAY_ACTIVITY = true;
            PLAY_ON_DESKTOP = true;
            PLAY_ON_PLAYSTATION = true;
            PLAY_ON_XBOX = true;
            WATCH_VIDEO = true;
            WATCH_VIDEO_ON_MOBILE = true;
          };
          autoCompleteQuestsSimultaneously = true;
          completeVideoQuestsQuicker = true;
          disableAccountPanelQuestProgress = true;
          disableOrbsAndQuestsBadges = true;
          disableSponsoredBanner = true;
          makeMobileVideoQuestsDesktopCompatible = true;
          preventVideoQuestsPausing = true;
          questButtonDisplay = "unclaimed";
          resumeInterruptedQuests = true;
          questButtonIncludedTypes = {
            "1" = true;
            "2" = true;
            "3" = true;
            "4" = true;
            "5" = true;
            WATCH_VIDEO = true;
            WATCH_VIDEO_ON_MOBILE = true;
            ACHIEVEMENT_IN_ACTIVITY = true;
            ACHIEVEMENT_IN_GAME = true;
            PLAY_ACTIVITY = true;
            STREAM_ON_DESKTOP = true;
            PLAY_ON_DESKTOP = true;
            PLAY_ON_DESKTOP_V2 = true;
            PLAY_ON_PLAYSTATION = true;
            PLAY_ON_XBOX = true;
          };
        };
      };
    };
    browser = {
      enable = true;
      client = "equicord";
      extraConfig.plugins = {
        Questify = {
          enabled = true;
          migrationVersion = 1;
          disableQuestsEverything = true;
        };
        AutoReact.enabled = true;
        LocalEdit.enabled = true;
        AddAttachments.enabled = true;
        AlwaysTrust.enabled = true;
        BetterCommands.enabled = true;
        BetterSettings.enabled = true;
        BetterUploadButton.enabled = true;
        ClearURLs.enabled = true;
        CopyFileContents.enabled = true;
        CopyStickerLinks.enabled = true;
        DragFavoriteEmotes.enabled = true;
        ExpressionCloner.enabled = true;
        FixCodeblockGap.enabled = true;
        FixFileExtensions.enabled = true;
        FixYoutubeEmbeds.enabled = true;
        GifPaste.enabled = true;
        GuildPickerDumper.enabled = true;
        HideMessages.enabled = true;
        HomeTyping.enabled = true;
        ImageZoom = {
          enabled = true;
          size = 500.0;
          square = true;
        };
        KeepCurrentChannel.enabled = true;
        MemberCount.enabled = true;
        MessageClickActions.enabled = true;
        MessageLogger = {
          enabled = true;
          collapseDeleted = true;
          ignoreSelf = true;
          inlineEdits = false;
          logEdits = false;
        };
        MoreUserTags = {
          enabled = true;
          dontShowBotTag = true;
          noAppsAllowed = true;
          tagSettings.VOICE_MODERATOR = {
            showInChat = false;
            showInNotChat = true;
          };
        };
        NewGuildSettings = {
          enabled = true;
          messages = 1;
        };
        NewPluginsManager.enabled = true;
        NoDevtoolsWarning.enabled = true;
        NoF1.enabled = true;
        NoMiddleClickPaste.enabled = true;
        NoNitroUpsell.enabled = true;
        NoOnboardingDelay.enabled = true;
        NoUnblockToJump.enabled = true;
        OnePingPerDM.enabled = true;
        PinIcon.enabled = true;
        PlatformIndicators.enabled = true;
        PreviewMessage.enabled = true;
        Quoter = {
          enabled = true;
          watermark = "Made by greyxp1";
        };
        ReactErrorDecoder.enabled = true;
        RelationshipNotifier.enabled = true;
        ReverseImageSearch.enabled = true;
        SearchFix.enabled = true;
        SendTimestamps.enabled = true;
        ShowAllMessageButtons.enabled = true;
        ShowTimeoutDuration.enabled = true;
        SilentTyping.enabled = true;
        StickerPaste.enabled = true;
        Translate.enabled = true;
        Unindent.enabled = true;
        ViewIcons = {
          enabled = true;
          format = "png";
          imgSize = "4096";
        };
        VoiceMessages = {
          enabled = true;
          echoCancellation = false;
          noiseSuppression = false;
        };
        WebContextMenus.enabled = true;
        WebKeybinds.enabled = true;
        WebScreenShareFixes.enabled = true;
        WhoReacted.enabled = true;
        YoutubeAdblock.enabled = true;
      };
    };
    quickCss = ''
      @import url(https://raw.githubusercontent.com/greyxp1/midnight-discord/0ada08471358e1d046fa39f3a2e0ca9c43adee61/build/midnight.css);
      @import url(https://mwittrien.github.io/BetterDiscordAddons/Themes/EmojiReplace/base/Apple.css);

      body {
          --background-image: on;
          --background-image-url: url('https://i.imgur.com/mOR0PoA.jpeg');
          --top-bar-height: var(--gap);
          --transparency-tweaks: on;
          --panel-blur: on;
          --blur-amount: 12px;
          --gap: 16px;
          --bg-floating: hsla(220, 15%, 13%, 0.6);
          --small-user-panel: off;
          --custom-chatbar: separated;
          --chatbar-height: 56px;
      }

      :root {
          --bg-4: hsla(220, 15%, 10%, 0.9);
          --text-0: hsla(220, 15%, 10%, 1);
          --text-1: hsl(220, 45%, 100%);
          --text-2: hsl(220, 25%, 90%);
          --text-3: hsl(220, 20%, 75%);
          --text-4: hsl(220, 15%, 55%);
          --text-5: hsl(220, 15%, 40%);
      }
    '';

    userPlugins = lib.mapAttrs (_: path: /. + builtins.unsafeDiscardStringContext path) {
      autoReact = "${inputs.cord-stash}/plugins/AutoReact";
      clientPreferences = "${inputs.cord-stash}/plugins/ClientPreferences";
      discordPopoutTitle = "${inputs.cord-stash}/plugins/DiscordPopoutTitle";
      fakeDeafen = "${inputs.cord-stash}/plugins/FakeDeafen";
      localEdit = "${inputs.cord-stash}/plugins/LocalEdit";
    };

    extraConfig = {
      useQuickCSS = true;
      plugins = {
        # Voice chat and screensharing
        ClientPreferences = {
          enabled = true;
          inputProfile = "STUDIO";
          qos = true;
          silenceWarning = false;
          sidechainCompression = false;
          attenuation = 0;
          attenuateWhileSpeakingSelf = false;
          attenuateWhileSpeakingOthers = false;
          channelSwitchWarning = false;
        };
        DiscordPopoutTitle.enabled = true;
        FakeDeafen.enabled = true;
        BlockKrisp.enabled = true;
        CallTimer = {
          enabled = true;
          format = "human";
        };
        DisableCallIdle.enabled = true;
        FakeNitro.enabled = true;
        FollowVoiceUser = {
          enabled = true;
          onlyWhenInVoice = false;
        };
        FullVCPFP.enabled = true;
        NoPushToTalk.enabled = true;
        UserVoiceShow.enabled = true;
        VoiceChannelLog.enabled = true;
        VoiceRejoin = {
          enabled = true;
          preventReconnectIfCallEnded = "none";
          rejoinDelay = 1.0;
          rejoinTimeout = 120.0;
        };
        WhosWatching.enabled = true;

        # Performance and stability
        Declutter = {
          enabled = true;
          alwaysShowUsername = true;
          removeAudioMenus = true;
          removeAvatarDecoration = true;
          removeBillingSettings = true;
          removeButtonTooltips = true;
          removeClanTag = true;
          removeDisplayNameStyles = true;
          removeFamilyCenterAboveDms = true;
          removeGiftButton = true;
          removeLibraryAboveDms = true;
          removeNameplate = true;
          removeProfileEffect = true;
          removeProfileFrame = true;
          removeQuestsAboveDms = false;
          removeServerBoostInfo = true;
          removeShopAboveDms = true;
          removeUnavailableEmojiPicker = true;
        };
        ConsoleJanitor = {
          enabled = true;
          disableLoggers = true;
        };
        CrashHandler.enabled = true;
        NoTypingAnimation.enabled = true;
      };
    };
  };
}
