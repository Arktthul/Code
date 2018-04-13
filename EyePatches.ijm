Dir1 = getDirectory("Choose Source Directory");
Dir2 = getDirectory("Choose Save Directory");
ImageList =getFileList(Dir1);
Array.show(ImageList);

for (k=0;k<ImageList.length; k++){
	path = Dir1+ImageList[k];
	open(path);
	run("Color Space Converter", "from=RGB to=LAB white=D65 separate");
	ImageNames=newArray(4);
	ImageNames = getList("image.titles");
	//Array.show(ImageNames);
	Name = ImageNames[0]+" (L*)";
setBatchMode(true);	
	//Name2 = ImageNames[0]+" (L*)_1";
	selectWindow(Name);//run("8-bit");
	run("Subtract Background...", "rolling=40 light");
	Name = replace(ImageNames[0], ".tif", "_");
	//print(Name);
	rename(Name);
	selectWindow(Name);saveAs("TIFF",Dir2+Name+"_cleaned");rename(Name);
	//remove Bristles
	selectWindow(Name);run("8-bit");
	setAutoThreshold("Minimum");run("Create Selection");run("Enlarge...", "enlarge=3");roiManager("Add");
	run("Select All");setAutoThreshold("Moments dark");run("Create Selection");run("Measure");
	AverageIntensity = getResult("Mean",0);print(AverageIntensity);
	roiManager("Select", 0); changeValues(-255,255,AverageIntensity);
	roiManager("Delete");selectWindow("Results");IJ.deleteRows(0, 0);
	selectWindow(Name);saveAs("TIFF",Dir2+Name+"_cleaned2");rename(Name);
	//
	//run("Duplicate...", Name2);//run("8-bit");
	run("Select All");
	getSelectionBounds(x, y, width, height);
	numberofRows= round(width/10);
	numberofColumns =round(height/10);
	NumberofRois = numberofRows*numberofColumns;
	for(i=0;i<numberofRows;i++){
		for(j=0;j<numberofColumns;j++){
			makeRectangle(i*10, j*10, 10, 10);
			roiManager("add");
		}
	}	
	run("Set Measurements...", "mean display redirect=None decimal=3");
	AverageIntensityRois = newArray(NumberofRois);
	for (i=0;i<NumberofRois;i++){
		roiManager("Select", i);
		run("Measure");
	}
	
	for (i=0;i<NumberofRois;i++){
		roiManager("Select", i);
		AverageIntensityRois[i] =getResult("Mean",i);
	}
	
	//Array.show(AverageIntensityRois);
	
	newImage("replace", "8-bit white", 10, 10, 1);
	
	for (i=0;i<NumberofRois;i++){
		Value = AverageIntensityRois[i];
		//print(Value);
		ReplacebyMean(Value,Name,i);
	}
//	setBatchMode(false);
	selectWindow(Name); rename(Name+"_binned");
	selectWindow(Name+"_binned"); 
	run("Select All");
	run("Duplicate...", Name+"_binned");rename(Name+"_swapped");
	
	newImage("transfer", "8-bit white", 10, 10, 1);
	//setBatchMode(true);
	for (i=0;i<NumberofRois*3;i++){
		Roi1 = floor(random()*NumberofRois);
		Roi2 = floor(random()*NumberofRois);
	//	print(Roi1,Roi2);
		swap(Roi1,Roi2,Name+"_swapped");
	}
//	setBatchMode(false);
	
	//Threshold
	selectWindow(Name+"_binned");
	setAutoThreshold("Moments");
	getThreshold(low, up);
//	print (low, up);
	run("Create Mask");rename(Name+"_binned_Mask");
	selectWindow(Name+"_swapped");
	setThreshold(low, up);run("Select All");
	run("Create Mask");
	rename(Name+"_swapped_Mask");
	//Save and Clean
//	setBatchMode(true);
	selectWindow(Name+"_swapped");saveAs("TIFF",Dir2+Name+"_swapped");
	selectWindow(Name+"_binned");saveAs("TIFF",Dir2+Name+"_binned");
	selectWindow(Name+"_swapped_Mask");run("Invert");saveAs("TIFF",Dir2+Name+"swapped_Mask");
	selectWindow(Name+"_binned_Mask");run("Invert");saveAs("TIFF",Dir2+Name+"_binned_Mask");
	
	roiManager("Select All");
	roiManager("Delete");
	close("transfer");close("replace");close("ImageNames");run("Close All");
	list = getList("window.titles"); 
    for (i=0; i<list.length; i++){ 
     winame = list[i]; 
     	selectWindow(winame); 
     run("Close"); 
     setBatchMode(false);
     } 
}
//Save Stack files
filename = Dir2+Name+"_swapped.tif"; print(filename);
run("Image Sequence...", "open="+Dir2+Name+"_binned.tif file=binned_Mask sort use");
saveAs("TIFF",Dir2+"binned_Stack");
run("Image Sequence...", "open="+Dir2+Name+"_swapped.tif file=swapped_Mask sort use");
saveAs("TIFF",Dir2+"swapped_Stack");close("swapped_Stack.tif");

//Measure Patches
run("Set Measurements...", "area mean display redirect=None decimal=3");
setBatchMode(true);
selectWindow("binned_Stack.tif");run("Duplicate...", "title=binned_Stack duplicate")
selectWindow("binned_Stack");run("Invert", "stack");close("binned_Stack.tif");
//run("Invert", "stack");
NumberPatches_Array=newArray(nSlices);
AveragePatch_Array=newArray(nSlices);
StdDevPatch_Array=newArray(nSlices);

for (i=1;i<=nSlices;i++){
	setSlice(i);
	//run("Invert", "slice");
	run("Analyze Particles...", "size=100-Infinity display add");
	NumberPatches=roiManager("count");
//	print(NumberPatches);
	if (NumberPatches ==0) {
		setSlice(i+1);
		i=i+1;
		run("Analyze Particles...", "size=100-Infinity display add");
		NumberPatches=roiManager("count");
	}
	//roiManager("Select All");
	//roiManager("Measure");
	AveragePatch=0;StdDev_Patch=0;SumArea=0;DiffAverage=0;SumDiffAverage=0;
	for (j=0; j<NumberPatches;j++){
		SumArea=getResult("Area",j)+SumArea;
//		print(getResult("Area",j));
//			waitForUser("pause");
	}
	AveragePatch = SumArea/NumberPatches;
	
	for (j=0; j<NumberPatches;j++){
		DiffAverage = (getResult("Area",j)-AveragePatch)*(getResult("Area",j)-AveragePatch);
		SumDiffAverage = DiffAverage+SumDiffAverage;print(SumDiffAverage);//waitForUser("Pause");
	}
	StdDev_Patch =  sqrt((SumDiffAverage)/(NumberPatches));
	roiManager("Select All");
	roiManager("Delete");
//Clean Results	
	list = getList("window.titles"); 
    for (l=0; l<list.length; l++){ 
     winame = list[l]; 
     	selectWindow(winame); 
     run("Close"); 
    }
	NumberPatches_Array[i-1] = NumberPatches;
	AveragePatch_Array[i-1] = AveragePatch;
	StdDevPatch_Array[i-1] = StdDev_Patch;
}
setBatchMode(false);
//CreateTable
for(i=0; i<nSlices; i++){
		setResult("Label", i, "Slice_"+(i+1));
		setResult("Number of Patches", nResults-1, NumberPatches_Array[i]);
		setResult("Average Patch area", nResults-1, AveragePatch_Array[i]);
		setResult("Std_Dev of Patch area", nResults-1, StdDevPatch_Array[i]);
	}



function swap(Roi1,Roi2,Name2) {
	selectWindow(Name2);
	roiManager("Select", Roi1);
	run("Copy");	
	selectWindow("transfer");
	run("Paste");
	selectWindow(Name2);
	roiManager("Select", Roi2);
	run("Copy");
	roiManager("Select", Roi1);
	run("Paste");
	selectWindow("transfer");
	run("Select All");
	run("Copy");
	selectWindow(Name2);
	roiManager("Select", Roi2);
	run("Paste");
	}

function ReplacebyMean(Value,Name,i) {
	selectWindow("replace");
	changeValues(-255, 255, Value);
	run("Select All");
	run("Copy");
	selectWindow(Name);
	roiManager("Select",i);
	run("Paste");
	selectWindow("replace");
	changeValues(-255, 255, 0);
		}




