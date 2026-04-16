%this is a script to joint part A and part B files of 2AFC experiments
%run in a directory that contains a bunch of subdirectories, each with a name or number for a participant
%each of the subdirectories should contain a .mat file ending in 'A' and another in 'B'
function join_data

dirs = dir;

for d = 3:length(dirs)%first two directories are always . and ..

    if dirs(d).isdir == 1%only if it is a directory
        
        cd(dirs(d).name);%enter the next directory
        
        files(1) = dir('*A.mat'); files(2) = dir('*B.mat');
        
        RT = []; KEY = []; SEQ = []; LIFT = [];
        
            for i = 1:2

                 load(files(i).name);

                 RT = [RT reactionTime]; KEY = [KEY keyPressed]; SEQ = [SEQ randomSequence]; %#ok<AGROW>

                 if exist('liftTime','var')
                     LIFT = [LIFT liftTime]; %#ok<AGROW>
                 end

            end

            reactionTime = RT; keyPressed = KEY; randomSequence = SEQ; liftTime = LIFT;

            %joint_file = files(1).name(1:end-6);%remove the last 6 characters of one of the filenames and save it
            
            joint_file = dirs(d).name;%no need to keep the date for the joint file
            
            save(joint_file,'reactionTime','keyPressed','randomSequence','liftTime');
            
            clearvars -except i files dirs %clean up the mess a little
            
            cd ..%get out of this directory
    end
    
end