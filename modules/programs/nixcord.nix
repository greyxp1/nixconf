{inputs, ...}: let
  cordStashPath = subpath:
    /. + builtins.unsafeDiscardStringContext "${inputs.cord-stash}/${subpath}";
in {
  flake.homeModules.nixcord = {
    imports = [inputs.nixcord.homeModules.nixcord];
    programs.nixcord = {
      enable = true;
      useGlobalPkgs = true;
      discord.enable = false;
      equibop = {
        enable = true;
        autoscroll.enable = true;
        state.firstLaunch = false;
        settings = {
          tray = false;
          hardwareVideoAcceleration = true;
          enableSplashScreen = false;
          splashTheming = false;
          staticTitle = true;
        };
      };

      quickCss = ''
        @import url(https://refact0r.github.io/midnight-discord/build/midnight.css);
        @import url(https://mwittrien.github.io/BetterDiscordAddons/Themes/EmojiReplace/base/Apple.css);

        body {
            --remove-bg-layer: on;
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
        autoReact = cordStashPath "plugins/AutoReact";
        betterAudioDefaults = cordStashPath "plugins/BetterAudioDefaults";
        fakeDeafen = cordStashPath "plugins/FakeDeafen";
        localEdit = cordStashPath "plugins/LocalEdit";
      };

      extraConfig = {
        plugins = {
          autoReact.enable = true;
          betterAudioDefaults.enable = true;
          fakeDeafen.enable = true;
          localEdit.enable = true;
        };
      };

      config = {
        useQuickCss = true;
        transparent = true;
        plugins = {
          alwaysTrust.enable = true;
          betterCommands.enable = true;
          betterSettings.enable = true;
          betterUploadButton.enable = true;
          blockKrisp.enable = true;
          callTimer = {
            enable = true;
            format = "human";
          };
          clearUrls.enable = true;
          consoleJanitor.enable = true;
          copyFileContents.enable = true;
          copyStickerLinks.enable = true;
          crashHandler.enable = true;
          declutter = {
            enable = true;
            removeAvatarDecoration = true;
            removeButtonTooltips = true;
            removeFamilyCenterAboveDms = true;
            removeLibraryAboveDms = true;
            removeShopAboveDms = true;
          };
          disableCallIdle.enable = true;
          dragFavoriteEmotes.enable = true;
          equibopStreamFixes = {
            enable = true;
            bitsPerPixelPct = 16;
            minBitrate = 6000;
          };
          expressionCloner.enable = true;
          fakeNitro.enable = true;
          fixCodeblockGap.enable = true;
          fixFileExtensions.enable = true;
          fixYoutubeEmbeds.enable = true;
          followVoiceUser = {
            enable = true;
            onlyWhenInVoice = false;
          };
          fullVcpfp.enable = true;
          gifPaste.enable = true;
          guildPickerDumper.enable = true;
          hideMessages.enable = true;
          homeTyping.enable = true;
          imageZoom = {
            enable = true;
            size = 500.0;
            square = true;
          };
          keepCurrentChannel.enable = true;
          memberCount.enable = true;
          messageClickActions.enable = true;
          messageLogger = {
            enable = true;
            collapseDeleted = true;
            ignoreSelf = true;
            inlineEdits = false;
            logEdits = false;
          };
          moreUserTags = {
            enable = true;
            dontShowBotTag = true;
            noAppsAllowed = true;
            tagSettings.voiceModerator.showInChat = false;
          };
          newGuildSettings = {
            enable = true;
            messages = 1;
          };
          newPluginsManager.enable = true;
          noDevtoolsWarning.enable = true;
          noF1.enable = true;
          noMiddleClickPaste.enable = true;
          noNitroUpsell.enable = true;
          noOnboardingDelay.enable = true;
          noPushToTalk.enable = true;
          noTypingAnimation.enable = true;
          noUnblockToJump.enable = true;
          onePingPerDm.enable = true;
          pinIcon.enable = true;
          platformIndicators.enable = true;
          previewMessage.enable = true;
          questify = {
            enable = true;
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
              ACHIEVEMENT_IN_ACTIVITY = true;
              ACHIEVEMENT_IN_GAME = true;
              PLAY_ACTIVITY = true;
              PLAY_ON_DESKTOP = true;
              PLAY_ON_DESKTOP_V2 = true;
              PLAY_ON_PLAYSTATION = true;
              PLAY_ON_XBOX = true;
              STREAM_ON_DESKTOP = true;
              WATCH_VIDEO = true;
              WATCH_VIDEO_ON_MOBILE = true;
            };
            resumeInterruptedQuests = true;
          };
          quoter = {
            enable = true;
            watermark = "Made by greyxp1";
          };
          reactErrorDecoder.enable = true;
          relationshipNotifier.enable = true;
          reverseImageSearch.enable = true;
          searchFix.enable = true;
          sendTimestamps.enable = true;
          showAllMessageButtons.enable = true;
          showTimeoutDuration.enable = true;
          silentTyping.enable = true;
          stickerPaste.enable = true;
          translate.enable = true;
          unindent.enable = true;
          userVoiceShow.enable = true;
          viewIcons = {
            enable = true;
            format = "png";
            imgSize = "4096";
          };
          voiceChannelLog.enable = true;
          voiceMessages = {
            enable = true;
            echoCancellation = false;
            noiseSuppression = false;
          };
          voiceRejoin = {
            enable = true;
            preventReconnectIfCallEnded = "none";
            rejoinDelay = 1.0;
            rejoinTimeout = 120.0;
          };
          webContextMenus.enable = true;
          webKeybinds.enable = true;
          webScreenShareFixes.enable = true;
          whoReacted.enable = true;
          whosWatching.enable = true;
          youtubeAdblock.enable = true;
        };
      };
    };
  };
}
