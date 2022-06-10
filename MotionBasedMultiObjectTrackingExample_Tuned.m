
function MotionBasedMultiObjectTrackingExample()

obj = setupSystemObjects();

tracks = initializeTracks(); 

nextId = 1; 


while hasFrame(obj.reader)
    frame = readFrame(obj.reader);
    [centroids, bboxes, mask] = detectObjects(frame);
    predictNewLocationsOfTracks();
    [assignments, unassignedTracks, unassignedDetections] = ...
        detectionToTrackAssignment();
    
    updateAssignedTracks();
    updateUnassignedTracks();
    deleteLostTracks();
    createNewTracks();
    
    displayTrackingResults();
end




%% Create System Objects

    function obj = setupSystemObjects()
       
        
        obj.reader = VideoReader('atrium_video3.mp4');
        
        
        obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);
        obj.maskPlayer1 = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer2 = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer3 = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer4 = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer5 = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer6 = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.VideoFWriter1=vision.VideoFileWriter('1.avi');
        obj.VideoFWriter3=vision.VideoFileWriter('2.avi');
        obj.VideoFWriter4=vision.VideoFileWriter('3.avi');
        obj.VideoFWriter6=vision.VideoFileWriter('4.avi');


        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        
        
        
        obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
            'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);
        
      
        
        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', 400);
    end

%% Initialize Tracks

    function tracks = initializeTracks()
        
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'totalVisibleCount', {}, ...
            'consecutiveInvisibleCount', {});
    end

%% Detect Objects


    function [centroids, bboxes, mask] = detectObjects(frame)
        
       
        mask = obj.detector.step(frame);
        
      
        mask = imopen(mask, strel('rectangle', [3,3]));
        mask = imclose(mask, strel('rectangle', [15, 15])); 
        mask = imfill(mask, 'holes');
        
        
        [~, centroids, bboxes] = obj.blobAnalyser.step(mask);
    end

%% Predict New Locations of Existing Tracks


    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;                
            predictedCentroid = predict(tracks(i).kalmanFilter);          
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
            tracks(i).bbox = [predictedCentroid, bbox(3:4)];
        end
    end

%% Assign Detections to Tracks


    function [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment()
        
        nTracks = length(tracks);
        nDetections = size(centroids, 1);
        
        % Compute the cost of assigning each detection to each track.
        cost = zeros(nTracks, nDetections);
        for i = 1:nTracks
            cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
        end
        
        % Solve the assignment problem.
        costOfNonAssignment = 20;
        [assignments, unassignedTracks, unassignedDetections] = ...
            assignDetectionsToTracks(cost, costOfNonAssignment);
    end

%% Update Assigned Tracks


    function updateAssignedTracks()
        numAssignedTracks = size(assignments, 1);
        for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = bboxes(detectionIdx, :);
            
            % Correct the estimate of the object's location
            % using the new detection.
            correct(tracks(trackIdx).kalmanFilter, centroid);
            
            % Replace predicted bounding box with detected
            % bounding box.
            tracks(trackIdx).bbox = bbox;
            
            % Update track's age.
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            
            % Update visibility.
            tracks(trackIdx).totalVisibleCount = ...
                tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
        end
    end

%% Update Unassigned Tracks


    function updateUnassignedTracks()
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
        end
    end

%% Delete Lost Tracks

    function deleteLostTracks()
        if isempty(tracks)
            return;
        end
        
        invisibleForTooLong = 20;
        ageThreshold = 8;
        
       
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;
        
        
        lostInds = (ages < ageThreshold & visibility < 0.6) | ...
            [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;
        
        
        tracks = tracks(~lostInds);
    end

%% Create New Tracks


    function createNewTracks()
        centroids = centroids(unassignedDetections, :);
        bboxes = bboxes(unassignedDetections, :);
        
        for i = 1:size(centroids, 1)
            
            centroid = centroids(i,:);
            bbox = bboxes(i, :);
            
           
            kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                centroid, [200, 50], [100, 25], 100);
            
            
            newTrack = struct(...
                'id', nextId, ...
                'bbox', bbox, ...
                'kalmanFilter', kalmanFilter, ...
                'age', 1, ...
                'totalVisibleCount', 1, ...
                'consecutiveInvisibleCount', 0);
            
            
            tracks(end + 1) = newTrack;
            
            
            nextId = nextId + 1;
        end
    end

%% Display Tracking Results


    function  displayTrackingResults()
        
        frame = im2uint8(frame);
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        global labels
        minVisibleCount = 8;
        if ~isempty(tracks)
           
            reliableTrackInds = ...
                [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);
            
           
            if ~isempty(reliableTracks)
                % Get bounding boxes.
                bboxes = cat(1, reliableTracks.bbox);
                              

                
                ids = int32([reliableTracks(:).id]);
                disp(ids)
                
                labels = cellstr(int2str(ids'));
                predictedTrackInds = ...
                    [reliableTracks(:).consecutiveInvisibleCount] > 0;
                isPredicted = cell(size(labels));
                isPredicted(predictedTrackInds) = {''};
                labels = strcat(labels, isPredicted);
                
                
                frame = insertObjectAnnotation(frame, 'rectangle', ...
                    bboxes, labels);
                
                
               
                mask=frame.*uint8(mask);
                mask = insertObjectAnnotation(mask, 'rectangle', ...
                    bboxes, labels);
                        
            end
        end
        
        
        
        
       
            
        mask=(imbinarize(mask));
        mask=filBox(mask,bboxes);
        mask=frame.*uint8(mask);
       
        [setFrames,map]=sepTracks(mask,bboxes,labels);
        
        
            m=size(map);
        
            for i=1:m(2)
             TrackMap=map{m(1),i};
             TrackId=TrackMap(1);
             TrackInd=TrackMap(2);
             if(TrackId==1)
               obj.maskPlayer1.step(setFrames(:,:,:,TrackInd))
               obj.VideoFWriter1.step(setFrames(:,:,:,TrackInd))
             end
             if(TrackId==3)
               obj.maskPlayer3.step(setFrames(:,:,:,TrackInd))
               obj.VideoFWriter3.step(setFrames(:,:,:,TrackInd))
             end
             if(TrackId==4)
               obj.maskPlayer.step(setFrames(:,:,:,TrackInd))
               obj.VideoFWriter4.step(setFrames(:,:,:,TrackInd))
             end
             if(TrackId==6)
               obj.maskPlayer5.step(setFrames(:,:,:,TrackInd))
               obj.VideoFWriter6.step(setFrames(:,:,:,TrackInd))
             end
             if(TrackId==7)
               ...obj.maskPlayer6.step(setFrames(:,:,:,TrackInd))
             end
         
             end
       .... uncomment if you want to see originals
        ...obj.maskPlayer.step(mask);
        ...obj.videoPlayer.step(frame);
        
    end

%% Summary


end
