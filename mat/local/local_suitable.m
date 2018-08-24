clear ;
clc;
load Sandiego.mat
load PlaneGT.mat
P=PlaneGT;
[S_h,S_w]=size(P);
get_target_index  %Get coordinate point coordinates

%Normalized
S_=Sandiego(1:100,1:100,10:79);  %S is the part of the upper left corner of 100*100, and a total of 70 bands of 10 to 79 are selected for analysis.
S_temp=zeros(100,100,70);
for i=1:100
    for j=1:100
        for k=1:70
            S_temp(i,j,k)=S_temp(i,j,k)+S_(i,j,k);
        end;
    end;
end;
S_temp=S_temp/70;
max_=max(max(S_temp));
max_=max_(:);
min_=min(min(S_temp));
min_=min_(:);
S=zeros(100,100,70);
for i=1:100
    for j=1:100
        for k=1:70
          S(i,j,:)=(S_temp(i,j,:)-min_(k))/(max_(k)-min_(k))*255;
        end;
    end;
end;
S=floor(S);


%% Adjustment

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Select the first target with a total of target_num pixels as the target  dictionary%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
target_num=9;
K=17;   %Sparsity
Inner=9;   %Inner Window size , suitable
Outer=13; %Outer Window size , suitable

%% 
T_index=1:target_sum;  %Disrupt the dictionary
for i=1:target_sum
    temp=floor(rand(1)*target_sum+1);
    temp2=target_index(T_index(i),:);
    target_index(T_index(i),:)=target_index(i,:);
    target_index(i,:)=temp2;
    
end;

Dict_t=zeros(70,target_num);
for i=1:target_num
    Dict_t(:,i)=S(target_index(i,1),target_index(i,2),:);  
end;

%% %%%%%%%%%%%%%%%%
%DUAL WINDOW  DESIGN
%inner window 
%outer window 
%      ����������������
%      |      outer             |
%      |           ����         |
%      |         | inner|       |
%      |         |         |       |
%      |           ����         |
%      ����������������
%%%%%%%%%%%%%%%%%%%


if rem(Outer,2)==0
    error('0x001:  Outer should be an odd number', 'Outer should be an odd number');
elseif rem(Inner,2)==0
    error('0x002:  Inner should be an odd number', 'Inner should be an odd number');
end;
new_H=Outer+99;
len=(Outer-1)*0.5;
b_num=Outer*Outer-Inner*Inner;   %Background dictionary number
%Boundary expansion == mirror expansion
S_expand=zeros(new_H,new_H,70);
for i=1:len
    S_expand((len+1):(100+len),i,:)=S(:,(len+2-i),:);   %Mirror symmetry
    S_expand((len+1):(100+len),i+len+100,:)=S(:,100-i,:);
end;
 S_expand((len+1):(100+len),(len+1):(100+len),:)=S(:,:,:);
for i=1:len
    S_expand(i,:,:)=S_expand(len*2-i+2,:,:);
    S_expand(i+100+len,:,:)=S_expand(100+len-i,:,:);
end;




%% Point-by-point detection of pixels

Dict_b=zeros(70,b_num);   
all_num=target_num+b_num;       %Overall dictionary number
Dict=zeros(70,all_num);
Residual=zeros(100,100);
z=zeros(70,1);
Z=zeros(70,all_num);
z=z(:);
for i=len+1:100+len
    for j=len+1:100+len
       Dict_b=get_dict_b(i,j,S_expand,Inner,(Outer-1)*0.5);
       Dict(:,1:b_num)=Dict_b(:,:);
       Dict(:,b_num+1:all_num)=Dict_t(:,:);   %Complete dictionary
       x1=S_expand(i,j,:);
       x2=S_expand(i-1,j,:);
       x3=S_expand(i,j-1,:);
       x4=S_expand(i+1,j,:);
       x5=S_expand(i,j+1,:);
       x1=x1(:);x2=x2(:);x3=x3(:);x4=x4(:);x5=x5(:);
       A=[4*Dict,-Dict,-Dict,-Dict,-Dict; Dict,Z,Z,Z,Z; Z,Dict,Z,Z,Z; Z,Z,Dict,Z,Z; Z,Z,Z,Dict,Z; Z,Z,Z,Z,Dict];
       X_=[z;x1;x2;x3;x4;x5];
       if i==20&&j==20
           disp('Dubug');
       end;
       GAMMA=OMP(X_,A,K);
       A1=GAMMA(1:all_num);
       A2=GAMMA((1+1*all_num):(2*all_num));
       A3=GAMMA((1+2*all_num):(3*all_num));
       A4=GAMMA((1+3*all_num):(4*all_num));
       A5=GAMMA((1+4*all_num):(5*all_num));
       alpha1=A1(1:b_num);
       alpha2=A2(1:b_num);
       alpha3=A3(1:b_num);
       alpha4=A4(1:b_num);
       alpha5=A5(1:b_num);
       beta1=A1((1+b_num):all_num);
       beta2=A2((1+b_num):all_num);
       beta3=A3((1+b_num):all_num);
       beta4=A4((1+b_num):all_num);
       beta5=A5((1+b_num):all_num);
       %calculate r_b=sqrt(sum|1->5 ||(x_i-A_b*beta_i)||2)
        %calculate r_t=sqrt(sum|1->5 ||(x_i-A_t*alpha_i)||2)

%        b1=norm(x1-Dict_b*alpha1);
%        b2=norm(x2-Dict_b*alpha2);
%        b3=norm(x3-Dict_b*alpha3);
%        b4=norm(x4-Dict_b*alpha4);
%        b5=norm(x5-Dict_b*alpha5);
%        a1=norm(x1-Dict_t*beta1);
%        a2=norm(x2-Dict_t*beta2);
%        a3=norm(x3-Dict_t*beta3);
%        a4=norm(x4-Dict_t*beta4);
%        a5=norm(x5-Dict_t*beta5);
%        r_b=sqrt(b1^2+b2^2+b3^2+b4^2+b5^2);
%        r_t=sqrt(a1^2+a2^2+a3^2+a4^2+a5^2);
%        Dx=r_b-r_t;
       b1=x1'*(x1-Dict_b*alpha1);
       b2=x2'*(x2-Dict_b*alpha2);
       b3=x3'*(x3-Dict_b*alpha3);
       b4=x4'*(x4-Dict_b*alpha4);
       b5=x5'*(x5-Dict_b*alpha5);
       a1=x1'*(x1-Dict_t*beta1);
       a2=x2'*(x2-Dict_t*beta2);
       a3=x3'*(x3-Dict_t*beta3);
       a4=x4'*(x4-Dict_t*beta4);
       a5=x5'*(x5-Dict_t*beta5);
%        r_b=sqrt(b1^2+b2^2+b3^2+b4^2+b5^2);
%        r_t=sqrt(a1^2+a2^2+a3^2+a4^2+a5^2);
       r_b=b1;r_t=a1;
       Dx=r_b/r_t;
       Residual(i-len,j-len)=Dx;
    end;
end;
    start_=min(min(Residual));end_=max(max(Residual)); step=(end_-start_)/2000;  %Ranges
    num=floor((end_-start_)/step)+1;
    coord=zeros(num,2);
    coord_index=1;
    MIN_DISTENCE=100000000;    %Record the optimal threshold
for threshold=start_:step:end_
    P_compare=zeros(P_h,P_w);
    for i=1+len:S_h-len
        for j=1+len:S_w-len
            if Residual(i,j)>threshold
                 P_compare(i,j)=1;
            end;
        end;
    end;
    sum_TP=0;    %True positive
    sum_FP=0;    %False positive
    sum_FN=0;    %False negative
    sum_TN=0;    %True negative
    for i=1+len:P_h-len
     for j=1+len:P_w-len
            if P_compare(i,j)==1&&PlaneGT(i,j)==1
             sum_TP=sum_TP+1;
            elseif P_compare(i,j)==0&&PlaneGT(i,j)==1
             sum_FN=sum_FN+1;
            elseif P_compare(i,j)==0&&PlaneGT(i,j)==0
             sum_TN=sum_TN+1;
            elseif P_compare(i,j)==1&&PlaneGT(i,j)==0
             sum_FP=sum_FP+1;
           end;
     end;
    end;
    FPR=sum_FP/(sum_FP+sum_TN);    %False positive rate
    TPR=sum_TP/(sum_TP+sum_FN);    %True positive rate
    distence=(FPR)^2+(1-TPR)^2;   %Calculate the distance from the upper left vertex, the shortest point can be considered the best threshold
    if distence<MIN_DISTENCE
        MIN_DISTENCE=distence;
        BEST_THRESHOLD=threshold;
    end;
    coord(coord_index,1)=FPR;
    coord(coord_index,2)=TPR;
    coord_index=coord_index+1;
end;
%% ROC curve
X=coord(:,1);
Y=coord(:,2);
figure;

plot(X,Y,'r'),xlabel('False alarm rate'),ylabel('Probability of detection'),title('ROC curve');%Output ROC curve

    
%% Plot

  P_compare=zeros(S_h,S_w);
    for i=1+len:S_h-len
        for j=1+len:S_w-len
            if Residual(i,j)>BEST_THRESHOLD
                 P_compare(i,j)=1;
            end;
        end;
    end;
figure;
imagesc(Residual),title('Residual');
figure;
subplot(1,2,1);
imshow(PlaneGT),title('GroundTruth');
subplot(1,2,2);
imshow(P_compare),title('Detect Result');