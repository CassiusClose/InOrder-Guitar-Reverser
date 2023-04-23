function y = synth_onset(x, frameLen, frameHop, onsets)
% Synthesize each onset as a 1-frame long white noise signal, and add it to
% the original audio signal.
%
% Input
%  - x          : input audio waveform
%  - frameLen   : frame length (in samples)
%  - frameHop   : frame hop size (in samples)
%  - onsets     : detected onsets (in frames)
% Output
%  - y          : output audio waveform which is the mixture of x and
%                   synthesized onset impulses

% Calculate number of frames in the signal
numFrames = ceil((length(x)-frameLen)/frameHop)+1;

% Pad the signal so it's an even number of framges
z = zeros((frameHop * (numFrames-1) + frameLen + 1) - length(x), 1);
x = [x; z];

% Calculate a frame of white noise, normalized between 0 & 1.
noise = randn(frameLen, 1);
noise = noise / max(abs(noise));

% For each detected onset, add the frame of noise to the onset's frame in
% the original audio signal
y = x;
for i=1:length(onsets)
    startInd = (onsets(i)-1)*frameHop + 1;
    endInd = startInd + frameLen - 1;
    
    y(startInd:endInd) = y(startInd:endInd) + noise;
end

% Normalize the audio to not clip
y = y / max(abs(y));
end