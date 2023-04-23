clear;
close all;
clc;


[audio, fs] = audioread("riff5.wav");

frameLen = 5000;
bufMax = 2*fs;

% Riff 1
% threshold = 0.004;
% minLen = 10000;

% Riff 3
% threshold = 0.009;
% minLen = 5000;

% Riff 4
threshold = 0.01;
minLen = 6000;

onsets = [];
allOnsets = [];

x2_prev = 0;
last_detected_onset = 0;
energy_prev = 0;

onsetFrameLen = 128;

derivs = zeros(ceil(length(audio)/onsetFrameLen), 1);

frameStart = 1;
frameCount = 1;
while(frameStart < length(audio))
    % Determine frame boundaries
    frameEnd = frameStart + frameLen - 1;
    if(frameEnd > length(audio))
        frameEnd = length(audio);
    end
    currFrameLen = frameEnd - frameStart + 1;
    
    frame = audio(frameStart:frameEnd);

%     numOnsetFrames = ceil(length(frame) / onsetFrameLen);
%     onsetFrameStart = 1;
%     for i=1:numOnsetFrames
%         onsetFrameEnd = onsetFrameStart + onsetFrameLen - 1;
%         if(onsetFrameEnd > length(frame))
%             onsetFrameEnd = length(frame);
%         end
%             
%         onsetFrame = frame(onsetFrameStart:onsetFrameEnd);
%         
%         energy = 0;
%         for j=1:length(onsetFrame)
%             energy = energy + onsetFrame(j)^2;
%         end
%         energy = energy/length(onsetFrame);
%         
%         deriv = energy - energy_prev;
%         derivs(frameCount) = deriv;
%         frameCount = frameCount+1;
%         
%         
%         startloc = frameStart + onsetFrameStart - 1;
%         endloc = frameStart + onsetFrameEnd - 1;
%         
%         if((deriv > threshold && startloc - last_detected_onset > minLen) || (endloc - last_detected_onset >= bufMax))
%             onsets = [onsets, onsetFrameStart];
%             allOnsets = [allOnsets, startloc];
%             last_detected_onset = endloc;
%         end        
%     end
    
    for i=1:length(frame)
        x = frame(i);
        x2 = x^2;

        deriv = x2 - x2_prev;
        loc = frameStart+i-1;

        if((deriv > threshold && loc-last_detected_onset > minLen) || (loc-last_detected_onset >= bufMax))
            onsets = [onsets, i];
            allOnsets = [allOnsets, loc];
            last_detected_onset = loc;
        end

        x2_prev = x2;
    end
    
    frameStart = frameStart + frameLen;
end

noiselen = 256;
noise = rand(noiselen, 1);

audio_noise = audio;

for o=allOnsets
    audio_noise(o:o+noiselen-1) = audio_noise(o:o+noiselen-1) + noise;
end
audio_noise = audio_noise/max(abs(audio_noise));



figure;
subplot(211);
hold on;
plot(audio);
for i=allOnsets
    xline(i, 'm');
end

subplot(212);
plot(derivs);

soundsc(audio_noise, fs);
