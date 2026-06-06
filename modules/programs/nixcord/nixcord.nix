{inputs, ...}: {
  flake.nixosModules.nixcord = {...}: {
    home-manager.sharedModules = [inputs.nixcord.homeModules.nixcord];
    home-manager.users.grey = {pkgs, ...}: {
      programs.nixcord = {
        enable = true;
        quickCss = builtins.readFile ./theme.css;

        discord = {
          enable = true;
          commandLineArgs = ["--"];
          vencord.enable = false;
          equicord.enable = true;
          settings.MINIMIZE_TO_TRAY = false;
          settings.openasar.setup = true;
          settings.openasar.quickstart = true;
        };

        equibop = {
          enable = true;
          state.firstLaunch = false;
          settings = {
            middleClickAutoscroll = true;
            tray = false;
            hardwareVideoAcceleration = true;
            enableSplashScreen = false;
            splashTheming = false;
            staticTitle = true;
          };

          package = pkgs.equibop.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.makeWrapper];
            postFixup =
              (old.postFixup or "")
              + ''
                wrapProgram $out/bin/equibop \
                  --add-flags "--force_high_performance_gpu" \
                  --add-flags "--enable-features=VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks" \
                  --add-flags "--ignore-gpu-blocklist"
              '';
          });
        };

        userPlugins.FakeDeafen = ./plugins/FakeDeafen;
        userPlugins.BetterAudioDefaults = ./plugins/BetterAudioDefaults;
        extraConfig.plugins.BetterAudioDefaults.enable = true;
        extraConfig.plugins.FakeDeafen.enable = true;

        config = {
          transparent = true;
          useQuickCss = true;
          plugins = {
            alwaysTrust.enable = true;
            betterCommands.enable = true;
            betterSettings.enable = true;
            betterUploadButton.enable = true;
            blockKrisp.enable = true;
            callTimer.enable = true;
            callTimer.format = "human";
            ClearURLs.enable = true;
            consoleJanitor.enable = true;
            copyFileContents.enable = true;
            copyStickerLinks.enable = true;
            crashHandler.enable = true;
            declutter.enable = true;
            declutter.removeShopAboveDM = true;
            disableCallIdle.enable = true;
            expressionCloner.enable = true;
            fakeNitro.enable = true;
            fixCodeblockGap.enable = true;
            fixFileExtensions.enable = true;
            fixImagesQuality.enable = true;
            fixYoutubeEmbeds.enable = true;
            followVoiceUser.enable = true;
            followVoiceUser.onlyWhenInVoice = false;
            fullSearchContext.enable = true;
            FullVCPFP.enable = true;
            gifPaste.enable = true;
            guildPickerDumper.enable = true;
            hideMessages.enable = true;
            homeTyping.enable = true;
            keepCurrentChannel.enable = true;
            memberCount.enable = true;
            messageClickActions.enable = true;
            micLoopbackTester.enable = true;
            moreUserTags.enable = true;
            newGuildSettings.enable = true;
            newGuildSettings.messages = 1;
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
            OnePingPerDM.enable = true;
            pinIcon.enable = true;
            platformIndicators.enable = true;
            previewMessage.enable = true;
            quoter.enable = true;
            quoter.watermark = "Made by greyxp1";
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
                #PLAY_ON_DESKTOP = true;
                #PLAY_ON_XBOX = true;
                #PLAY_ON_PLAYSTATION = true;
                #PLAY_ACTIVITY = true;
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
          };
        };
      };
    };
  };
}
