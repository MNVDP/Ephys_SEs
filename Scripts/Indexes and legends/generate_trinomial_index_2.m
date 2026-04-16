clear all

nums = zeros(3^5,5);

%generate all possible combinations of 3 item vectors ordered by their value in ternary numbers
for i = 1:length(nums)
   aux = dec2base(i-1,3,5);
   nums(i,:) = [str2double(aux(1)) str2double(aux(2)) str2double(aux(3)) str2double(aux(4)) str2double(aux(5))]; 
end

first_nums = zeros(3^5,3);

for i = 1:length(nums)
    [b m n] = unique(nums(i,:),'first');
    
    first_nums(i,1:length(m)) = m;
end

% first_nums = sort(first_nums,2);
% 
% [b m n] = unique(first_nums,'rows');

%save('index_trinomial','index_trinomial');