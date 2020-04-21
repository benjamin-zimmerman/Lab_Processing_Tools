% fslMNIvol_2TAL
% Ben Zimmerman 4/20/2020
function FSLxform = fslMNIvol_2TAL(in, ref)

% Builds transform from MNI to TAL space. Transformation from MNI to
% Talairach space is complicated since Talairach space doesn't have an
% associated image. People who have been working on this have determined
% that depending on which software your MNI image is from can alter the
% results. A transform is provided based on http://brainmap.org/icbm2tal/.

% The citation is https://www.ncbi.nlm.nih.gov/pubmed/17266101.
% This function relies on load_nii function.

%Unfortunately, transforming volumes into the space isn't as easy as
%applying the transformation matrix. From the fsl forum, here are the
%instructions for building the correct transforms. This is a simple
%function that probably needs to be altered depending on the sform or qform
%codes in the data. 

%An alternative is to get the best affine matrix from the get_best_affine()
%function in nibabel for python.

% If both input and output images have a negative determinant for their sform 
% (or qform) then the formula for the conversion is:
% 
% FSLmat = scale_ref * inv(sform_ref) * icbm_fsl * sform_in * inv(scale_in)
% where scale_ref = diag([pixdim1 pixdim2 pixdim3 1]) for pixdims associated 
% with the reference image, and scale_in is defined similarly.
% 
% If you have a positive determinant for either image then you also need to 
% insert an appropriate swapping matrix next to the scale matrix.  
% For example, swap_ref = [-1 0 0 Nx-1 ; 0 1 0 0 ; 0 0 1 0 ; 0 0 0 1] where 
% Nx = number of voxels in the x direction (for the reference image in this 
% case) and it would go inside the scale_ref (i.e. scale_ref * swap_ref 
% * inv(sform_ref) * ....) and for the input would be 
% (... * swap_in * inv(scale_in) )

in = load_nii(in);
ref = load_nii(ref);


icbm_fsl = [0.9464 0.0034 -0.0026 -1.0680
		   -0.0083 0.9479 -0.0580 -1.0239
            0.0053 0.0617  0.9010  3.1883
            0.0000 0.0000  0.0000  1.0000];
        

scale_ref = diag([ref.hdr.dime.pixdim(2) ref.hdr.dime.pixdim(3) ref.hdr.dime.pixdim(4) 1]);
scale_in = diag([in.hdr.dime.pixdim(2) in.hdr.dime.pixdim(3) in.hdr.dime.pixdim(4) 1]);

sform_ref = ([ref.hdr.hist.srow_x; ref.hdr.hist.srow_y; ref.hdr.hist.srow_z; 0 0 0 1]);
sform_in = ([in.hdr.hist.srow_x; in.hdr.hist.srow_y; in.hdr.hist.srow_z; 0 0 0 1]);

FSLxform = scale_ref * inv(sform_ref) * icbm_fsl * sform_in * inv(scale_in);