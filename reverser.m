% REVERSER EFFECT
% Cassius Close
%
% This script takes in an audio signal and reverses each note seperately,
% so that the notes are still in the same order, just their waveforms are
% reversed.
%
% It does some form of onset detection to determine where notes start. The
% note data is read into a 'read buffer', and when the next note starts,
% the previous note is put into a 'write buffer', which is continually read
% from to output samples. Then the next note's data starts collecting in
% the read buffer.


clear;
close all;
clc;

% Read input audio
[audio, fs] = audioread("SampleAudio/riff.wav");
% audio = 1:308701;
% fs = 44100;

% Audio output stream
deviceWriter = audioDeviceWriter('SampleRate', fs, 'SupportVariableSizeInput', true);


% The while loop below simulates a stream of input data by breaking the
% audio into frames & processing them one at a time. This is the size of
% each frame in samples.
frameLen = 5000;




% Initialize buffers & variables
r = ReverserData(fs);


% Store the entire output signal for displaying it
output = [];




% -- EFFECT SETTINGS --
% Threshold: The threshold for treating a note as an onset or not. Above
%               the threshold is an onset, below is not.
% Min Onset Time: The minimum time (in seconds) between two onsets. If an
%               onset is detected before this time has elapsed, it will not
%               be counted.


% Riff 1
% threshold = 0.05;
threshold = 0.004;
minOnsetTime = 0.22;

% Riff 3
% threshold = 0.009;
% minLen = 10000;

% Riff 4
% threshold = 0.004;
% minLen = 6000;

% Convert min onset time to samples
minLen = minOnsetTime*fs;



% -- UI settings --
% mix = parameterRef;
% mix.name = "Mix";
% mix.value = 0.3;
% 
% bufSize = parameterRef;
% bufSize.name = "Frame Length";
% bufSize.value = bufMax/2;
% 
% parametersTuningUI([bufSize, mix], [[bufMin, bufMax]; [0, 1]]);




% -- Tracking Note Boundaries --

% The output signal will have a bunch of individual notes that
% have been reversed. To keep track of the boundaries between
% the notes, whenever an entire note is "flushed" from the read
% buffer to the write buffer, we can keep track of how much
% data that note consists of, and mark the boundaries
% accordingly.
%
% Sometimes, when a very short note is followed by a very long
% note, the write buffer will run out of data. The first note
% will finish being played before the second note ends, so
% there will be a period of silence until the second note ends.
% We need to keep track of this so that we can set the note
% boundaries in the right place. This is done with the ReverserData.emptyLen
% variable.

% Stores how much data has been written so far
writeAmount = 0;
% The sample index location of each boundary
boundaries = [0];





% -- Onset Detection Variables -- 

% Stores the sample index location of the last detected onset
last_detected_onset = 0;

% Stores the previous sample value squared, used to calculate change
% between current & previous sample.
x2_prev = 0;

% Each frame, holds the onsets detected in that frame
frameOnsets = [];
% A list of all the onsets detected in the entire audio, to display at the
% end
onsets = [];

% Debugging
% preOnsets = [36664, 48596, 61632, 71707, 103483, 114944, 125220, 135919, 146904,...
%     169761, 205079, 215291, 225694, 235911, 248201, 293328, 303654];
% onsets = preOnsets;




% -- Process Audio --
% Simulate a stream of data, breaking the audio into frames that are
% processed one at a time.

% The index of the first sample in the current frame
frameStart = 1;
while(frameStart < length(audio))
    % -- Determine frame boundaries --
    
    % The index of the last sample in the current frame
    frameEnd = frameStart + frameLen - 1;
    if(frameEnd > length(audio))
        frameEnd = length(audio);
    end
    
    % The length of current frame
    currFrameLen = frameEnd - frameStart + 1;
    
    % Extract frame
    frame = audio(frameStart:frameEnd);
    
    
    
    % -- Detect onsets within the frame. --
    % Currently, the onset detection works on a sample by sample basis,
    % comparing the values between two samples. This doesn't work that
    % well, except on super clean guitar signals & tuning of the min onset
    % time. So the method will be changed in the future.
    
    % There is some minimum time that is allowed to pass between onsets.
    % 
    % Also, because the buffers are only so big, there is some maximum
    % amount of time that is allowed to pass between onsets, otherwise the
    % buffer would fill up & lose data.
    for i=1:length(frame)
        % Work with squared values, so we can detect increasing energy,
        % whether or not it's increasing positively or negatively
        x2 = frame(i)^2;
        
        % The amplitude derivative (change between last sample & this one)
        deriv = x2 - x2_prev;
        
        % The index of the sample in regard to the entire audio clip
        loc = frameStart+i-1;
        
        % The sample is considered an onset if:
        %   - The derivative is greater than some threshold
        %   - The minimum amount of time has passed since the last onset
        %       was detected
        %
        %   - Or, if the maximum amount of time has passed since the last
        %       onset was detected, treat it as an onset no matter what.
        if((deriv > threshold && loc-last_detected_onset > minLen) || (loc-last_detected_onset >= r.bufMax))
            frameOnsets = [frameOnsets, i];
            onsets = [onsets, loc];
            last_detected_onset = loc;
        end
        
        % Save the most recent sample
        x2_prev = x2;
    end
    
          
    % -- Update settings from UI -- 
%     drawnow limitrate
%     bufSize.value = round(bufSize.value);      

    
    % Display debug messages for specific ranges of time
    if(frameEnd > 0*100000 && frameStart < 5.7*100000)
        r.debug = false;
    else
        r.debug = false;
    end
    

    

    % -- Process each note --
    % For each onset detected in the current frame, process the data, flip
    % it, and put it into the write buffer.
    
    % If there are several onsets within the frame, we will break each note
    % into it's own piece of audio & flip it. This index keeps track of
    % where the unprocessed frame data starts (i.e., where the current
    % note's data starts in the frame)
    frameCpyInd = 1;
    while(~isempty(frameOnsets))
        % The number of samples that belong with the current note in this
        % frame. (The number of samples to copy to the read buffer). If
        % this is the first onset in the frame, then the note might have
        % samples from previous frames already stored in the read buffer,
        % but they are not included in this amount.
        rCopyLen = frameOnsets(1) - (frameCpyInd - 1);
        
        if(r.debug)
            fprintf("\nCopying %d to readbuf\n", rCopyLen);
            fprintf("Next onset: %d\n", frameOnsets(1));
            fprintf("Frame Copy Start: %d\n", frameCpyInd);
            fprintf("Readbufind: %d\n", r.readBufInd);
        end
        
        
        % Copy data over to read buffer
        r.writeToReadBuf(frame(frameCpyInd:frameCpyInd+rCopyLen-1));

        
        % Mark the new start of unread frame data
        frameCpyInd = frameCpyInd + rCopyLen;
        
        % Remove the onset we just processed from the list
        frameOnsets = frameOnsets(2:end);
        
        
        % Now that we've reached an onset, we can take the note's data,
        % flip it, and put in into the write buffer so it can be output.
        
        % If the write buffer is empty, then there are a couple of things
        % that need to be done.
        if(r.writeBufEmpty)
            % Sometimes, when a very short note is followed by a very long
            % note, the write buffer will run out of data. The first note
            % will finish being played before the second note ends, so
            % there will be a period of silence until the second note ends.
            % We need to keep track of this so that we can set the note
            % boundaries in the right place. So when the write buffer runs
            % out of data, we must record how many samples the write buffer
            % is empty for (stored in r.emptyLen), and then add that to the
            % next boundary location.
            writeAmount = writeAmount + r.emptyLen;
            r.emptyLen = 0;
            r.writeBufEmpty = false;

            
            % When the write buffer is empty and the next note is being
            % flushed, we start writing the note's data directly at the
            % read index, so the note will be played as soon as possible.
            % (Set this here because when the write buffer is empty, the
            % write index continues to get moved, so it gets out of sync
            % with the read index).
            r.writeBufWriteInd = r.writeBufReadInd;
        end

        % Flush the read buffer into the write buffer. Returns the amount
        % of data flushed
        len = r.flushReadBuf();
        
        % Place a boundary directly after the note
        writeAmount = writeAmount + len;
        boundaries = [boundaries, writeAmount];
    end
    
    % At this point, there are no onsets left in the frame, so all that's
    % left to do is to copy the rest of the data to the read buffer, to
    % wait there until an onset comes along in another frame.

    % How much data to copy to the read buffer
    rCopyLen = currFrameLen - frameCpyInd + 1;
    
    % If there is data to copy, then copy it to the read buffer
    if(rCopyLen > 0)
        r.writeToReadBuf(frame(frameCpyInd:frameCpyInd+rCopyLen-1));
    end
    
    
    
    
    % Grab output samples from the write buffer
    frameOut = r.popWriteBuf(frameLen);
    
    % Play the samples
    deviceWriter(frameOut);
    
    
    % Keep track of output signal to display it
    output = [output; frameOut];
    
    
    % Move to the next frame
    frameStart = frameStart + frameLen;
end


% -- Flush leftover data --
% We've finished processing the audio file, but there is data left in the
% read buffer, so flush that to the write buffer, and then output whatever
% is remaining in the write buffer.

if(r.debug)
    fprintf("\nFlushing %d..\n", r.readBufInd);
end

% If the write buffer is empty, then there are a couple of things
% that need to be done.
if(r.writeBufEmpty)
    % Sometimes, when a very short note is followed by a very long
    % note, the write buffer will run out of data. The first note
    % will finish being played before the second note ends, so
    % there will be a period of silence until the second note ends.
    % We need to keep track of this so that we can set the note
    % boundaries in the right place. So when the write buffer runs
    % out of data, we must record how many samples the write buffer
    % is empty for (stored in r.emptyLen), and then add that to the
    % next boundary location.
    writeAmount = writeAmount + r.emptyLen;
    r.emptyLen = 0;
    r.writeBufEmpty = false;


    % When the write buffer is empty and the next note is being
    % flushed, we start writing the note's data directly at the
    % read index, so the note will be played as soon as possible.
    % (Set this here because when the write buffer is empty, the
    % write index continues to get moved, so it gets out of sync
    % with the read index).
    r.writeBufWriteInd = r.writeBufReadInd;
end

% Flush the read buffer into the write buffer. Returns the amount
% of data flushed
len = r.flushReadBuf();

% Place a boundary directly after the note
writeAmount = writeAmount + len;
boundaries = [boundaries, writeAmount];


% Get the rest of the write buffer data & output it
rest = r.popWriteBuf();
deviceWriter(rest);
 
% Keep track of output signal to display it
output = [output; rest];


% Display results
figure;

% Plot the original signal, with the onsets displayed
subplot(211);
hold on;
t = linspace(0, length(audio)/fs, length(audio));
plot(t, audio);
for o=onsets
    xline(o/fs, 'm');
end
title("Original Signal w/ Onsets");
xlabel("Time (s)");
ylabel("Amplitude");
legend(["Original Signal", "Detected Onsets"]);

% Plot the output signal, with note boundaries displayed
subplot(212);
hold on;
t = linspace(0, length(output)/fs, length(output));
plot(t, output);
for b=boundaries
    xline(b/fs, 'm');
end
title("Output Signal w/ Frame Boundaries");
xlabel("Time (s)");
ylabel("Amplitude");
legend(["Output Signal", "Frame Boundaries"]);


% Clean up
release(deviceWriter);