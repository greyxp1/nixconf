{inputs, ...}: {
  flake.wrappers.helium = {pkgs, ...}: {
    equicord = {
      package = pkgs.callPackage (inputs.nixcord.outPath + "/pkgs/equicord") {};
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

      userPlugins = {
        autoReact = "${inputs.cord-stash}/plugins/AutoReact";
        betterAudioDefaults = "${inputs.cord-stash}/plugins/BetterAudioDefaults";
        discordPopoutTitle = "${inputs.cord-stash}/plugins/DiscordPopoutTitle";
        fakeDeafen = "${inputs.cord-stash}/plugins/FakeDeafen";
        localEdit = "${inputs.cord-stash}/plugins/LocalEdit";
      };

      settings = {
        useQuickCSS = true;
        plugins = {
          # User plugins
          AutoReact.enabled = true;
          BetterAudioDefaults.enabled = true;
          DiscordPopoutTitle.enabled = true;
          FakeDeafen.enabled = true;
          LocalEdit.enabled = true;

          # Normal plugins
          AddAttachments.enabled = true;
          AlwaysTrust.enabled = true;
          BetterCommands.enabled = true;
          BetterSettings.enabled = true;
          BetterUploadButton.enabled = true;
          BlockKrisp.enabled = true;
          CallTimer = {
            enabled = true;
            format = "human";
          };
          ClearURLs.enabled = true;
          ConsoleJanitor.enabled = true;
          CopyFileContents.enabled = true;
          CopyStickerLinks.enabled = true;
          CrashHandler.enabled = true;
          Declutter = {
            enabled = true;
            removeAvatarDecoration = true;
            removeButtonTooltips = true;
            removeFamilyCenterAboveDms = true;
            removeLibraryAboveDms = true;
            removeShopAboveDms = true;
          };
          DisableCallIdle.enabled = true;
          DragFavoriteEmotes.enabled = true;
          ExpressionCloner.enabled = true;
          FakeNitro.enabled = true;
          FixCodeblockGap.enabled = true;
          FixFileExtensions.enabled = true;
          FixYoutubeEmbeds.enabled = true;
          FollowVoiceUser = {
            enabled = true;
            onlyWhenInVoice = false;
          };
          FullVCPFP.enabled = true;
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
            tagSettings.VOICE_MODERATOR.showInChat = false;
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
          NoPushToTalk.enabled = true;
          NoTypingAnimation.enabled = true;
          NoUnblockToJump.enabled = true;
          OnePingPerDM.enabled = true;
          PinIcon.enabled = true;
          PlatformIndicators.enabled = true;
          PreviewMessage.enabled = true;
          Questify = {
            enabled = true;
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
            questButtonIncludedTypes = {
              "1" = false;
              "2" = false;
              "3" = false;
              "4" = true;
              "5" = true;
              WATCH_VIDEO = true;
              WATCH_VIDEO_ON_MOBILE = true;
              ACHIEVEMENT_IN_ACTIVITY = false;
              ACHIEVEMENT_IN_GAME = false;
              PLAY_ACTIVITY = false;
              STREAM_ON_DESKTOP = false;
              PLAY_ON_DESKTOP = false;
              PLAY_ON_DESKTOP_V2 = false;
              PLAY_ON_PLAYSTATION = false;
              PLAY_ON_XBOX = false;
            };
            resumeInterruptedQuests = true;
          };
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
          UserVoiceShow.enabled = true;
          ViewIcons = {
            enabled = true;
            format = "png";
            imgSize = "4096";
          };
          VoiceChannelLog.enabled = true;
          VoiceMessages = {
            enabled = true;
            echoCancellation = false;
            noiseSuppression = false;
          };
          VoiceRejoin = {
            enabled = true;
            preventReconnectIfCallEnded = "none";
            rejoinDelay = 1.0;
            rejoinTimeout = 120.0;
          };
          WebContextMenus.enabled = true;
          WebKeybinds.enabled = true;
          WebScreenShareFixes.enabled = true;
          WhoReacted.enabled = true;
          WhosWatching.enabled = true;
          YoutubeAdblock.enabled = true;
        };
      };
    };
  };
}
