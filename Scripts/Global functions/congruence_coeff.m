function [cg] = congruence_coeff(f1,f2)

cg = dot(f1(:,1),f2(:,1))/sqrt((dot(f1(:,1),f1(:,1))*dot(f2(:,1),f2(:,1))));