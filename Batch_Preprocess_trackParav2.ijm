input = getDirectory("Input Directory");
output1 = getDirectory("Output Directory For Paramecia"); // Output images to the same directory as input (prevents second dialogue box, otherwise getDirectory("Output Directory"))
output2 = getDirectory("Output Directory For Eyes");
Dialog.create("File Type");
Dialog.addString("File Suffix: ", ".avi", 5); // Select another file format if desired
suffix = Dialog.getString();

processFolder(input, output1,output2);

// Scan folders/subfolders/files to locate files with the correct suffix

function processFolder(input, output1,output2) {
	list = getFileList(input);
	j = 0;
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			if(j == 0){
				t = process1stFilePara(input, output1, list[i]);
				t2 = process1stFileEyes(input, output2, list[i],t[2],t[3],t[4],t[5]);
				j = 1;
			}
			else{
				processFilesPara(input,output1,list[i],t[0],t[1],t[2],t[3],t[4],t[5]);
				processFilesEyes(input,output2,list[i],t2[0],t2[1],t[2],t[3],t[4],t[5]);
			}
			
	}
	run("Close All");
}


function process1stFilePara(input, output, file) {
	open(input + "\\" + file);
	
	orig = getTitle();
	origname = replace(orig,".avi","");
	
	// Crop the data
	run("Specify...", "width=100 height=100 x=88 y=122 slice=1");
	waitForUser("Pause", "Select region of eyes + paramecia"); // Ask for input ROI
	run("Properties... ", "name=crop position=none stroke=none width=0 fill=none list");
	results = getTitle();

	saveAs("Results", output1 + "XY-" + origname + ".csv");
	//prop = getTitle();
	//prop = "XY_" + prop;
	X1 =getResult("X",0); X2 =getResult("X",1); X3 =getResult("X",2); X4 =getResult("X",3);
	Y1 =getResult("Y",0); Y2 =getResult("Y",1); Y3 =getResult("Y",2); Y4 =getResult("Y",3);
	width = X2-X1; height = Y3-Y2;
	//t0 = getNumber("Initial frame", 1);
	//t1 = getNumber("Last frame", getSliceNumber());
	selectWindow(orig);
	run("Duplicate...", "duplicate");
	//run("Duplicate...", "duplicate range=" + toString(t0) + "-" + toString(t1));
	run("Properties...", "channels=1 slices=1 frames=" + toString(nSlices) + " frame=[3.33 msec]");
	//saveAs("Tiff", dir_output + origname + "-cropped");
	cropped = getTitle();
	run("Duplicate...", "duplicate");
	// Sharpen the edges and reduce grain noise
	//run("Gamma...", "value=3 stack"); // optional for adjusting the contrast
	run("Unsharp Mask...", "radius=10 mask=0.9 stack");
	run("Gaussian Blur...", "sigma=1 stack");
	//run("Duplicate...", "duplicate");
	
	// Background subtraction
	stack = getTitle();
	//waitForUser("Pause", "Select background image"); // Ask for input ROI
	setSlice(nSlices);
	run("Duplicate...", "use");
	background = getTitle();
	para = getNumber("How many paramecia?", 1);
	for(i = 0;i<para;i++){
	waitForUser("Pause", "If there's any paramecia, draw ROI."); // Ask for input ROI
	run("Median...", "radius=20");
	}
	run("Select None");
	imageCalculator("Difference create stack", stack,background);
	
	
	// Threshold the image
	setAutoThreshold("Default");
	//run("Threshold...");
	setThreshold(50, 255);
	waitForUser("Pause", "Press CTRL + SHIFT + T then adjust the threshold");
	t0 = getNumber("1st threshold", 50);
	t1 = getNumber("2nd threshold", 255);
	t = newArray(t0,t1,X1,Y1,width,height);
	setThreshold(t[0], t[1]);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	
	//run("Duplicate...", "duplicate");
	
	// Optional processing; morphological filters; 
	// WARNING: Computationally expensive, takes a lot of time, and memory. Only use if necessary
	
	//run("Morphological Filters (3D)", "operation=Erosion element=[Horizontal Line] x-radius=1 y-radius=1 z-radius=1");
	
	//run("Morphological Filters (3D)", 
	//	"operation=Dilation element=Ball x-radius=1 y-radius=1 z-radius=10");
	//run("Morphological Filters (3D)", 
	//	"operation=Closing element=Ball x-radius=2 y-radius=2 z-radius=15");
	saveAs("Tiff", output + origname + "-bin_para");
	run("Close");
	//run("Close All");
	
	selectWindow(orig);
	run("Close");
	selectWindow(cropped);
	run("Close");
	selectWindow(stack);
	run("Close");

	return t;
}
	
function process1stFileEyes(input, output, file,X1,Y1,width,height) {
	open(input + "\\" + file);
	orig = getTitle();
	origname = replace(orig,".avi","");

	//selectWindow(c);
	//X1 =getResult("X",0); X2 =getResult("X",1); X3 =getResult("X",2); X4 =getResult("X",3);
	//Y1 =getResult("X",0); Y2 =getResult("X",1); Y3 =getResult("X",2); Y4 =getResult("X",3);
	//width = X2-X1; height = Y3-Y2;
	run("Specify...", "width=" + width + " height=" + height + " x=" + X1 + " y=" + Y1 + " slice=1");
	// Crop the data
	//run("Restore Selection");
	//waitForUser("Pause", "Select the frame for eye positions");
	selectWindow(orig);
	run("Duplicate...", "use");
	setThreshold(20, 50);
	waitForUser("Pause", "Press CTRL + SHIFT + T then adjust the threshold");
	t0 = getNumber("1st threshold", 20);
	t1 = getNumber("2nd threshold", 55);
	t = newArray(t0,t1);
	setThreshold(t[0], t[1]);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	saveAs("Tiff", output + origname + "-bin_eyes");
	run("Close All");
	//selectWindow(origname + "-bin_eyes.tif");
	//run("Close");
	//selectWindow(orig);
	//run("Close");
	//selectWindow(orig);
		// Optional processing; morphological filters; 
	// WARNING: Computationally expensive, takes a lot of time, and memory. Only use if necessary
	
	//run("Morphological Filters (3D)", "operation=Erosion element=[Horizontal Line] x-radius=1 y-radius=1 z-radius=1");
	
	//run("Morphological Filters (3D)", 
	//	"operation=Dilation element=Ball x-radius=1 y-radius=1 z-radius=10");
	//run("Morphological Filters (3D)", 
	//	"operation=Closing element=Ball x-radius=2 y-radius=2 z-radius=15");
	return t;
}	

function processFilesPara(input, output, file,t0,t1,X1,Y1,width,height) {
	open(input + "\\" + file);
	orig = getTitle();
	origname = replace(orig,".avi","");
	
	// Crop the data
	//run("Specify...", "width= height=100 x=88 y=122 slice=1");
	//selectWindow(c);
	//X1 =getResult("X",0); X2 =getResult("X",1); X3 =getResult("X",2); X4 =getResult("X",3);
	//Y1 =getResult("X",0); Y2 =getResult("X",1); Y3 =getResult("X",2); Y4 =getResult("X",3);
	//width = X2-X1; height = Y3-Y2;
	selectWindow(orig);
	run("Specify...", "width=" + width + " height=" + height + " x=" + X1 + " y=" + Y1 + " slice=1");
	run("Duplicate...", "duplicate");
	//run("Duplicate...", "duplicate range=" + toString(t0) + "-" + toString(t1));
	run("Properties...", "channels=1 slices=1 frames=" + toString(nSlices) + " frame=[3.33 msec]");
	//saveAs("Tiff", dir_output + origname + "-cropped");
	cropped = getTitle();
	run("Duplicate...", "duplicate");
	// Sharpen the edges and reduce grain noise
	//run("Gamma...", "value=3 stack"); // optional for adjusting the contrast
	run("Unsharp Mask...", "radius=10 mask=0.9 stack");
	run("Gaussian Blur...", "sigma=1 stack");
	//run("Duplicate...", "duplicate");
	
	// Background subtraction
	stack = getTitle();
	//waitForUser("Pause", "Select background image"); // Ask for input ROI
	setSlice(nSlices);
	run("Duplicate...", "use");
	background = getTitle();
	para = getNumber("How many paramecia?", 1);
	for(i = 0;i<para;i++){
	waitForUser("Pause", "If there's any paramecia, draw ROI."); // Ask for input ROI
	run("Median...", "radius=20");
	}
	run("Select None");
	imageCalculator("Difference create stack", stack,background);

	// Threshold the image
	setAutoThreshold("Default");
	//run("Threshold...");
	setThreshold(t0, t1);
	//waitForUser("Pause", "Press CTRL + SHIFT + T then adjust the threshold");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	run("Duplicate...", "duplicate");
	
	// Optional processing; morphological filters; 
	// WARNING: Computationally expensive, takes a lot of time, and memory. Only use if necessary
	
	//run("Morphological Filters (3D)", "operation=Erosion element=[Horizontal Line] x-radius=1 y-radius=1 z-radius=1");
	
	//run("Morphological Filters (3D)", 
	//	"operation=Dilation element=Ball x-radius=1 y-radius=1 z-radius=10");
	//run("Morphological Filters (3D)", 
	//	"operation=Closing element=Ball x-radius=2 y-radius=2 z-radius=15");
	saveAs("Tiff", output + origname + "-bin_para");
	run("Close All");
	//selectWindow(orig);
	//run("Close");
	//selectWindow(cropped);
	//run("Close");
	//selectWindow(stack);
	//run("Close");
}

function processFilesEyes(input, output, file,t0,t1,X1,Y1,width,height) {
	open(input + "\\" + file);
	orig = getTitle();
	origname = replace(orig,".avi","");
	
	// Crop the data
	//run("Restore Selection");
	//waitForUser("Pause", "Select the frame for eye positions");
	//selectWindow(c);
	//X1 =getResult("X",0); X2 =getResult("X",1); X3 =getResult("X",2); X4 =getResult("X",3);
	//Y1 =getResult("X",0); Y2 =getResult("X",1); Y3 =getResult("X",2); Y4 =getResult("X",3);
	//width = X2-X1; height = Y3-Y2;
	run("Specify...", "width=" + width + " height=" + height + " x=" + X1 + " y=" + Y1 + " slice=1");
	run("Duplicate...", "use");
	//waitForUser("Pause", "Press CTRL + SHIFT + T then adjust the threshold");
	setThreshold(t0, t1);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Light");
	saveAs("Tiff", output + origname + "-bin_eyes");
	run("Close All");
	//selectWindow(origname + "-bin_eyes.tif");
	//run("Close");
	//selectWindow(orig);
	//run("Close");
		// Optional processing; morphological filters; 
	// WARNING: Computationally expensive, takes a lot of time, and memory. Only use if necessary
	
	//run("Morphological Filters (3D)", "operation=Erosion element=[Horizontal Line] x-radius=1 y-radius=1 z-radius=1");
	
	//run("Morphological Filters (3D)", 
	//	"operation=Dilation element=Ball x-radius=1 y-radius=1 z-radius=10");
	//run("Morphological Filters (3D)", 
	//	"operation=Closing element=Ball x-radius=2 y-radius=2 z-radius=15");
}	
		
print("Batch done.");