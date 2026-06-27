{inputs, ...}: {
  flake.nixosModules.nixcord = _: {
    home-manager.sharedModules = [inputs.nixcord.homeModules.nixcord];
    home-manager.users.grey = _: {
      programs.nixcord = {
        enable = true;
        quickCss = builtins.readFile ./theme.css;

        discord = {
          enable = true;
          equicord.enable = true;
          settings = {
            #SKIP_HOST_UPDATE = true;
            #SKIP_MODULE_UPDATE = true;
            #USE_NEW_UPDATER = false;
            MINIMIZE_TO_TRAY = false;
            openasar = {
              setup = true;
              quickstart = true;
            };
          };

          commandLineArgs = [
            "--enable-features=VaapiVideoDecoder"
            "--enable-blink-features=MiddleClickAutoscroll"
            "--ozone-platform-hint=auto"
          ];
        };

        userPlugins = {
          FakeDeafen = ./plugins/FakeDeafen;
          BetterAudioDefaults = ./plugins/BetterAudioDefaults;
        };

        extraConfig.plugins = {
          BetterAudioDefaults.enable = true;
          FakeDeafen.enable = true;
        };

        config = {
          transparent = true;
          useQuickCss = true;
          plugins = {
            alwaysTrust.enable = true;
            betterCommands.enable = true;
            betterSettings.enable = true;
            betterUploadButton.enable = true;
            blockKrisp.enable = true;
            clearUrls.enable = true;
            consoleJanitor.enable = true;
            copyFileContents.enable = true;
            copyStickerLinks.enable = true;
            crashHandler.enable = true;
            disableCallIdle.enable = true;
            expressionCloner.enable = true;
            fakeNitro.enable = true;
            fixCodeblockGap.enable = true;
            fixFileExtensions.enable = true;
            fixImagesQuality.enable = true;
            fixYoutubeEmbeds.enable = true;
            fullSearchContext.enable = true;
            fullVcpfp.enable = true;
            gifPaste.enable = true;
            guildPickerDumper.enable = true;
            hideMessages.enable = true;
            homeTyping.enable = true;
            keepCurrentChannel.enable = true;
            memberCount.enable = true;
            messageClickActions.enable = true;
            micLoopbackTester.enable = true;
            newPluginsManager.enable = true;
            noDevtoolsWarning.enable = true;
            noF1.enable = true;
            noMiddleClickPaste.enable = true;
            noMosaic.enable = true;
            noNitroUpsell.enable = true;
            noOnboardingDelay.enable = true;
            noPushToTalk.enable = true;
            noTypingAnimation.enable = true;
            noUnblockToJump.enable = true;
            onePingPerDm.enable = true;
            pinIcon.enable = true;
            platformIndicators.enable = true;
            previewMessage.enable = true;
            reactErrorDecoder.enable = true;
            relationshipNotifier.enable = true;
            remixRevived.enable = true;
            reverseImageSearch.enable = true;
            roleColorEverywhere.enable = true;
            searchFix.enable = true;
            showAllMessageButtons.enable = true;
            sendTimestamps.enable = true;
            showTimeoutDuration.enable = true;
            stickerPaste.enable = true;
            translate.enable = true;
            unindent.enable = true;
            userVoiceShow.enable = true;
            voiceChannelLog.enable = true;
            webContextMenus.enable = true;
            webKeybinds.enable = true;
            webScreenShareFixes.enable = true;
            whoReacted.enable = true;
            whosWatching.enable = true;
            youtubeAdblock.enable = true;
            zipPreview.enable = true;

            questify = {
              enable = true;
              allowChangingDangerousSettings = true;
              autoCompleteQuestsSimultaneously = true;
              completeVideoQuestsQuicker = true;
              disableAccountPanelPromo = true;
              disableAccountPanelQuestProgress = true;
              disableFriendsListPromo = true;
              disableMembersListPromo = true;
              disableOrbsAndQuestsBadges = true;
              disableSponsoredBanner = true;
              makeMobileVideoQuestsDesktopCompatible = true;
              questButtonDisplay = "unclaimed";
              resumeInterruptedQuests = true;
              autoCompleteQuestTypes = {
                PLAY_ON_DESKTOP = true;
                PLAY_ON_XBOX = true;
                PLAY_ON_PLAYSTATION = true;
                PLAY_ACTIVITY = true;
                WATCH_VIDEO = true;
                WATCH_VIDEO_ON_MOBILE = true;
                ACHIEVEMENT_IN_ACTIVITY = true;
              };
            };

            messageLoggerEnhanced = {
              enable = true;
              attachmentSizeLimitInMegabytes = 500;
              cacheMessagesFromServers = true;
              ignoreSelf = true;
              messageLimit = 0;
              saveImages = true;
            };

            messageLogger = {
              enable = true;
              collapseDeleted = true;
              ignoreSelf = true;
              separatedDiffs = true;
              showEditDiffs = true;
            };

            moreUserTags = {
              enable = true;
              dontShowBotTag = true;
              noAppsAllowed = true;
              tagSettings.voiceModerator.showInChat = false;
            };

            voiceRejoin = {
              enable = true;
              preventReconnectIfCallEnded = "none";
              rejoinDelay = 1.0;
              rejoinTimeout = 120.0;
            };

            equibopStreamFixes = {
              enable = true;
              minBitrate = 10000;
              bitsPerPixelPct = 16;
            };

            voiceMessages = {
              enable = true;
              echoCancellation = false;
              noiseSuppression = false;
            };

            imageZoom = {
              enable = true;
              square = true;
              size = 500.0;
            };

            viewIcons = {
              enable = true;
              format = "png";
              imgSize = "4096";
            };

            callTimer = {
              enable = true;
              format = "human";
            };

            declutter = {
              enable = true;
              removeShopAboveDms = true;
            };

            followVoiceUser = {
              enable = true;
              onlyWhenInVoice = false;
            };

            newGuildSettings = {
              enable = true;
              messages = 1;
            };

            quoter = {
              enable = true;
              watermark = "Made by greyxp1";
            };
          };
        };
      };
    };
  };
}
