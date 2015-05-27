#!/bin/bash
## Ben Zimmerman 5/21/2015
## THIS SCRIPT TAKES THE DICOM FILES FROM A VASO EXPERIMENT AND ORGANIZES THEM INTO SEPARATE FOLDERS, ANALYZES THEM, AND PRODUCES RESULTS. THE ONLY THING THAT YOU WILL NEED TO CHANGE IS THE LOCATION OF THE PROJECT FOLDER AND THE SCRIPT SHOULD RUN FINE. 

# THE SCRIPT ASSUMES 
# 	1) THE PROTOCOL USED CONSISTS OF A LOCALIZER SCAN, 10 VARYING TI TIMES, AN OVERLAY, AND AN ANATOMICAL MPRAGE IN THAT ORDER. MAKE SURE TO ADJUST THE NUMBERS TO CORRECTLY POPULATE THE ANALYSIS FOLDERS.

#	2) THE DICOMS ARE LABELED FROM SUTTON_SEQTESTING PROTOCOLS

#	3) THERE ARE 3 LOC FILES, 20 DICOM FILES FOR EACH INVERSION TIME (INCLUDING NO INVERSION), 600 DICOM FILES FOR THE OVERLAY IMAGES, 192 DICOM FILES FOR THE MPRAGE

#	4) FSL AND DCM2NII (MRICRON) ARE ON THE COMPUTER

## NOTES

# DOUBLE CHECK THE NUMBER OF DICOM FILES IN THE OVERLAY BECAUSE THIS HAS BEEN VARIABLE OVER ACQUISITIONS. SIMPLY CHANGE THE NUMBER INDICATED BY THE "head" COMMAND WHEN YOU INITIALLY POPULATE THE FOLDERS.

# THE MIDDLE SLICE OF THE OVERLAY IMAGE HAS ALSO CHANGED ACROSS ACQUISITIONS. FSLROI NEEDS TO KNOW WHAT SLICE IS THE CENTER OF THE OVERLAY; DOUBLE CHECK TO MAKE SURE THAT THE FSLROI SLICE YOU'RE PULLING OUT MATCHES THE MIDDLE SLICE FROM AVG_OVERLAY
#----------------------------------------------------------------

# CHANGE THIS TO THE LOCATION OF YOUR PROCESSING FOLDER WITH THE DICOM IMAGES
myproject='/home/ben/Documents/WindowsShare/VASO/'


sublist='TI_0389
TI_0464
TI_0539
TI_0614
TI_0689
TI_0764
TI_0839
TI_0914
TI_0989
TI_1064'

cd ${myproject}

mkdir Alternating_TR Overlay MPRAGE loc

cd Alternating_TR

mkdir ${sublist} No_Inversion Results 

cd ${myproject}

# LOOPS TO MOVE FILES TO FOLDERS...BEWARE THAT THIS ASSUMES YOU HAVE LOC FILES! IF YOU DON'T HAVE LOC FILES YOU MUST COMMENT OUT THE FIRST LOOP


# MOVE 3 LOC FILES

# ls *.IMA | sort -n | head -3 | xargs -i mv "{}" Alternating_TR/loc

# MOVE 20 VASO IMAGES TO EACH OF THE 10 DIFFERENT INVERSION TIME FOLDERS

for sub in ${sublist}
do 

ls *.IMA | sort -n | head -20 | xargs -i mv "{}" Alternating_TR/${sub}

done

# MOVE 20 NO INVERSION IMAGES TO THE NO INVERSION FOLDER

ls *.IMA | sort -n | head -20 | xargs -i mv "{}" Alternating_TR/No_Inversion

# MOVE THE 600 OVERLAY IMAGES INTO THE OVERLAY FOLDER; BE SURE TO CHECK THE NUMBER OF OVERLAY DICOMS, AS THIS HAS BEEN VARIABLE.

ls *.IMA | sort -n| head -600 | xargs -i mv "{}" Overlay

# MOVE THE 192 MPRAGE IMAGES INTO THE MPRAGE FOLDER

ls *.IMA | sort -n| head -192 | xargs -i mv "{}" MPRAGE

##------------------------------------------------------------
# NOW USE DCM2NII TO BUILD THE NII FILES

# STARTING WITH THE INVERSION FOLDERS

for sub in ${sublist}
do
	cd Alternating_TR/${sub}
		
## Convert .ima files to .nii.gz files

	dcm2nii *.IMA

## The dcm2nii stacks the images in the z axis instead of in time. Split the stack! But let's BET it first.
	
	fslmaths *.nii.gz -nan unsplit_nan

	# bet unsplit_nan bet_unsplit_nan -m	

	fslsplit unsplit_nan splat -z

## Now stick them back together in the time domain, but leave out the first two images (splat 0000, and splat 0001), since they are prior to steady state.
	
	rm splat0000.nii.gz splat0001.nii.gz

	fslmerge -t ${sub} splat*
	
	bet ${sub} ${sub}_bet -m
	
	cd ${myproject}

done

# DCM2NII FOR THE NO_INVERSION CASE

	cd Alternating_TR/No_Inversion
		
## Convert .ima files to .nii.gz files

	dcm2nii *.IMA

## The dcm2nii stacks the images in the z axis instead of in time. Split the stack! But let's BET it first.
	
	fslmaths *.nii.gz -nan unsplit_nan

	# bet unsplit_nan bet_unsplit_nan -m	

	fslsplit unsplit_nan splat -z

## Now stick them back together in the time domain, but leave out the first two images (splat 0000, and splat 0001), since they are prior to steady state.
	
	rm splat0000.nii.gz splat0001.nii.gz

	fslmerge -t No_Inversion splat*
	
	bet No_Inversion No_Inversion_bet -m
	
	cd ${myproject}

# DCM2NII FOR THE OVERLAY

	cd Overlay

	dcm2nii *.IMA

## The dcm2nii stacks each sample in the z axis. Split the stack! Then average.

	fslmaths *.nii.gz -nan unsplit_nan
	
	fslsplit unsplit_nan splat 
	
	fslmaths splat0000 -add splat0001 -add splat0002 -add splat0003 -add splat0004 -add splat0005 -add splat0006 -add splat0007 -add splat0008 -add splat0009 -add splat0010 -add splat0011 -add splat0012 -add splat0013 -add splat0014 -add splat0015 -add splat0016 -add splat0017 -add splat0018 -add splat0019 -div 20 avg_overlay
	
	bet avg_overlay avg_overlay_bet -m

cd ${myproject}

# DCM2NII FOR THE MPRAGE; THE BETTING OPTIONS AND FAST MAKE THIS STEP TAKE A WHILE
	
	cd MPRAGE
	
	dcm2nii *.IMA

	bet o*.nii.gz bet_mprage -m -B -f 0.1
	
	fast bet_mprage

cd ${myproject}

## PROCESS THE DIFFERENT VASO INVERSION TIME IMAGES

	
	
for sub in ${sublist}
do
	cd Alternating_TR/${sub}
		
asl_file --data=${sub} --ntis=1 --iaf=ct --diff --out=${sub}_diff --mean=${sub}_diff_mean

## You can use this if you want avg signals over the whole slice

#fslmeants -i ${sub}_diff_mean -m ${sub}_bet_mask -o ${sub}_avg_brain_signal.txt

	cd ${myproject}

done

## PROCESS THE NO_INVERSION IMAGE

	cd Alternating_TR/No_Inversion
		
asl_file --data=No_Inversion --ntis=1 --iaf=ct --diff --out=No_Inversion_diff --mean=No_Inversion_diff_mean

## You can use this if you want avg signals over the whole slice

#fslmeants -i No_Inversion_diff_mean -m No_Inversion_bet_mask -o No_Inversion_avg_brain_signal.txt

	cd ${myproject}

## USE BBR through epi_reg function TO IMPROVE REGISTRATION

	## betting the t2 is extremely important on a few subjects, use -B to get rid of bias and extra neck (it does both); This also takes quite a bit of time
       
epi_reg --epi=Overlay/avg_overlay_bet.nii.gz --t1=MPRAGE/o*.nii.gz --t1brain=MPRAGE/bet_mprage.nii.gz  --out==bbr_overlay2struc.nii.gz

##epi_reg outputs the transformation matrix automatically 

convert_xfm -omat bbr_struc2overlay.mat -inverse bbr_overlay2struc_init.mat

##Use the next line to output structural to functional images if interested##

flirt -in MPRAGE/bet_mprage.nii.gz -ref Overlay/avg_overlay_bet.nii.gz -applyxfm -init bbr_struc2overlay.mat -out bbr_struc2overlay.nii.gz
    
## Apply the inverted transform to the MPRAGE-derived gray/white matter masks

flirt -in MPRAGE/bet_mprage_pve_1 -ref Overlay/avg_overlay_bet.nii.gz -applyxfm -init bbr_struc2overlay.mat -out bbr_gray_mask

flirt -in MPRAGE/bet_mprage_pve_2 -ref Overlay/avg_overlay_bet.nii.gz -applyxfm -init bbr_struc2overlay.mat -out bbr_white_mask
    
    ## Threshold the masks
    ## fslmeants with those masks.	
	
fslmaths bbr_gray_mask -thr 0.6 bbr_gray_mask

## Let's use a very stringent white matter mask to make sure that we're only getting white matter values for our calculations, then we can avg over the whole mask.

fslmaths bbr_white_mask -thr 0.9 bbr_white_mask

# Be careful here about picking the middle slice in the overlay image
fslroi bbr_gray_mask good_slice_gray_mask 0 64 0 64 15 1
fslroi bbr_white_mask good_slice_white_mask 0 64 0 64 15 1

## Get the same slice of white matter for the white matter signal calculation

fslmeants -i Alternating_TR/No_Inversion/No_Inversion_bet.nii.gz -m good_slice_white_mask.nii.gz -o WM_NO_VASO_SIGNAL.txt


for sub in ${sublist} 
do 
		
cd Alternating_TR/${sub}/

	fslmeants -i ${sub}_diff_mean.nii.gz -m ../../good_slice_gray_mask.nii.gz -o ../Results/${sub}_avg_GM_VASO_signal.txt

	cd ${myproject}
	
done

echo "Finished"




