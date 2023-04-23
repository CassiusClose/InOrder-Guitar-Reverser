function [updated_reverser] = flush(r)
    
    load("test.mat");
    
    
    HELLO = "TEST";
    
    save("test.mat");

%     % flush
%     if(r.debug)
%         fprintf("\nFlushing %d..\n", r.readBufInd);
%     end
% 
%     data = copyFromCircularBuf(r.readBuf, 1, r.readBufInd-1);
%     zeroData(r.readBuf, 1, r.readBufInd-1);
%     data = flip(data);
% 
%     if(r.debug)
% %             printArray(data, length(data));
%     end
% 
% 
%     if(r.writeAmount == 0)
%         r.boundaries = [length(data)];
%         r.writeAmount = length(data);
%     end
% 
%     if(r.overlap > 0)
%         r.writeAmount = r.writeAmount + r.overlap + rCopyLen;
%         r.overlap = 0;
%     end
% 
%     if(r.writeBufWriteInd == -1)
% %             writeAmount = writeAmount + rCopyLen;
% %             boundaries = [boundaries, writeAmount];
% 
%         r.writeBufWriteInd = r.writeBufReadInd+rCopyLen;
%         if(r.writeBufWriteInd > length(r.writeBuf))
%             r.writeBufWriteInd = r.writeBufWriteInd - length(r.writeBuf);
%         end
%     end
% 
%     if(r.writeBufWriteInd == -2)
% %             if(frameStart > 150000)
% %                 fprintf("\n\nDOING\n\n");
% %                 writeBufWriteInd = writeBufReadInd;
% %             else
% %             writeAmount = writeAmount + rCopyLen;
%         r.writeBufWriteInd = r.writeBufReadInd+rCopyLen;
%         if(r.writeBufWriteInd > length(r.writeBuf))
%             r.writeBufWriteInd = r.writeBufWriteInd - length(r.writeBuf);
%         end
% %             end
%     end
% 
%     if(r.writeBufWriteInd < r.writeBufReadInd)
%         writefill = length(r.writeBuf) - (r.writeBufReadInd - r.writeBufWriteInd);
%     else
%         writefill = r.writeBufWriteInd - r.writeBufReadInd;
%     end
% 
%     if(length(r.writeBuf) - writefill < length(data)) 
%         fprintf("OVERLAP DETECTED\n");
%         fprintf("fill: %d\n", writefill);
%         fprintf("space: %d\n", length(r.writeBuf) - writefill);
%         fprintf("data len: %d\n", length(data));
%         return;
%     end
% 
%     if(r.debug)
%         fprintf("Writing %d into writeBuf\n", length(data));
%         fprintf("WriteBuf WriteInd: %d\n", r.writeBufWriteInd);
%         fprintf("WriteBuf ReadInd: %d\n", r.writeBufReadInd);
%     end
% 
%     r.writeBuf = copyToCircularBuf(r.writeBuf, r.writeBufWriteInd, data);
%     r.writeBufWriteInd = r.writeBufWriteInd + length(data);
%     if(r.writeBufWriteInd > length(r.writeBuf))
%         r.writeBufWriteInd = r.writeBufWriteInd - length(r.writeBuf);
%         if(r.writeBufWriteInd > r.writeBufReadInd)
%             fprintf("ERROR: DATA OVERLAP\n");
%             return;
%         end
%     end
% 
%     if(r.debug)
%         fprintf("WriteBuf WriteInd: %d\n", r.writeBufWriteInd);
%         fprintf("WriteBuf ReadInd: %d\n", r.writeBufReadInd);
%     end
% 
% 
% 
%     r.writeAmount = r.writeAmount + length(data);
%     r.boundaries = [r.boundaries, r.writeAmount];
% 
%     if(debug)
% 
%         if(r.writeBufWriteInd < r.writeBufReadInd)
%             fprintf("writebuf fill: %d\n\n", length(r.writeBuf) - (r.writeBufReadInd - r.writeBufWriteInd));
%         else
%             fprintf("writebuf fill: %d\n\n", r.writeBufWriteInd - r.writeBufReadInd);
%         end
%     end
% %         fullOut = [fullOut; data];
%     r.readBuf = zeros(r.bufMax, 1);
%     r.readBufInd = 1;
% 
%     if(r.debug)
% 
% %             fprintf("WriteBuf Read Index: %d\n", writeBufReadInd);
% %             printArray(writeBuf, writeBufReadInd);
%     end
%     
%     updated_reverser = r;
end