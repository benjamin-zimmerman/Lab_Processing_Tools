% Ben Zimmerman
% 4/22/2020
% This code provides a general strategy for translating an MRI image by
% some number of voxels. It is rough and should be adjusted for various
% cases.

% Based loosely off of Antonello's script for moving the infant atlases,
% but improved to allow for easily understanding shifts in negative directions.


MRI_hdrh=spm_vol('\\bi-cnl-nas1.beckman.illinois.edu\data\bhf\opt-crd\rest\occipital_TAL_ROI.nii');
head=spm_read_vols(MRI_hdrh);

new_space = 20;
% In order to move the head, you need to know the AC offset (in mm). I add
% 10 spaces to the border of the head.
mask1=zeros(size(head)+ new_space);
% This is the offset
x=0;
y=2;
%z=-3.5;
z= -4;
DIM=size(head);

% first move the dimensions by the amount that you added
mask1((new_space/2-x):DIM(1)+(new_space/2-x)-1 ,(new_space/2-y):DIM(2)+(new_space/2-y)-1, (new_space/2-z):DIM(3)+(new_space/2-z)-1)=head;

%now you have shifted mask, which you can move around in the expanded
%space.

mask2=zeros(size(head));
mask2 = mask1(new_space/2:DIM(1)+new_space/2-1, new_space/2:DIM(2)+new_space/2-1, new_space/2:DIM(3)+new_space/2-1);


figure
imagesc(squeeze(head(:,:,30)))

figure
imagesc(squeeze(mask1(:,:,30)))

figure
imagesc(squeeze(mask2(:,:,30)))


MRI_hdrm1=MRI_hdrh;
MRI_hdrm1.fname=[MRI_hdrh.fname(1:end-4),'_opt3d_test.nii'];
spm_write_vol(MRI_hdrm1,mask2);




