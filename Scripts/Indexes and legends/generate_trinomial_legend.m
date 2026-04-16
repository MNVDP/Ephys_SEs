clear all

nums = zeros(243,5);

for i = 1:243
   aux = dec2base(i-1,3,5);
   nums(i,:) = [str2double(aux(1)) str2double(aux(2)) str2double(aux(3)) str2double(aux(4)) str2double(aux(5))]; 
end

nums_logic = zeros(243,5);

for i = 1:243
    nums_logic(i,nums(i,:) == nums(i,1)) = 0;
    aux = 1;
    for j = 2:5
           if nnz(nums(i,1:j-1) == nums(i,j)) == 0%if a new element
              nums_logic(i,nums(i,:) == nums(i,j)) = aux;
              aux = aux + 1;
           end
    end 
end

aux = unique(nums_logic,'rows');

aux(aux == 0) = 'A'; aux(aux == 1) = 'B'; aux(aux == 2) = 'C';

trinomial_legend = char(aux);

trinomial_legend = cellstr(trinomial_legend);

save('trinomial_legend','trinomial_legend');