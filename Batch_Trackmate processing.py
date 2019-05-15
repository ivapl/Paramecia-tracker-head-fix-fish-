from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import Logger
from fiji.plugin.trackmate.detection import LogDetectorFactory
from fiji.plugin.trackmate.tracking.sparselap import SparseLAPTrackerFactory
from fiji.plugin.trackmate.tracking import LAPUtils
from ij import IJ, WindowManager
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
import sys
import fiji.plugin.trackmate.features.track.TrackDurationAnalyzer as TrackDurationAnalyzer
from itertools import izip_longest
import csv
import os
# INPUT ------------------------
dir_input = "C:\\Users\\Semmelhack Lab\\Documents\\test_freeswim_data\\results\\"
dir_output = dir_input + "\\results\\"
Radius = 8.0 # Size of the paramecia in pixel unit; should be a float
Spot_thres = 1. # Threshold value for selecting spots 1.00-100.00; should be a float
Spot_quality = 1 # Spot quality 1- 100
TrackDisp_filter = 10.0  # Filter for the tracks in pixel displacement
# ---------------------------

files = []
for file in os.listdir(dir_input):  # read files with .csv then store the filename to files
    if file.endswith(".tif"):
        files.append(file)
        
for file in files:
	# Get currently selected image
	imp = IJ.openImage(dir_input + file)
	imp.show()
	    
	    
	#----------------------------
	# Create the model object now
	#----------------------------
	    
	# Some of the parameters we configure below need to have
	# a reference to the model at creation. So we create an
	# empty model now.
	    
	model = Model()
	    
	# Send all messages to ImageJ log window.
	model.setLogger(Logger.IJ_LOGGER)
	    
	    
	       
	#------------------------
	# Prepare settings object
	#------------------------
	       
	settings = Settings()
	settings.setFrom(imp)
	       
	# Configure detector - We use the Strings for the keys
	settings.detectorFactory = LogDetectorFactory()
	settings.detectorSettings = { 
	    'DO_SUBPIXEL_LOCALIZATION' : True,
	    'RADIUS' : Radius,
	    'TARGET_CHANNEL' : 1,
	    'THRESHOLD' : Spot_thres,
	    'DO_MEDIAN_FILTERING' : False,
	}  
	    
	# Configure spot filters - Classical filter on quality
	filter1 = FeatureFilter('QUALITY', Spot_quality, True)
	settings.addSpotFilter(filter1)
	     
	# Configure tracker - We want to allow merges and fusions
	settings.trackerFactory = SparseLAPTrackerFactory()
	#settings.trackerFactory ={
	#	'LINKING_MAX_DISTANCE' : 10,
	#	'GAP-CLOSING_MAX_DISTANCE': 10,
	#	'GAP-CLOSING_MAX_FRAME_GAP': 2,
	#}
	settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap() # almost good enough
	settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = True
	settings.trackerSettings['ALLOW_TRACK_MERGING'] = True
	    
	# Configure track analyzers - Later on we want to filter out tracks 
	# based on their displacement, so we need to state that we want 
	# track displacement to be calculated. By default, out of the GUI, 
	# not features are calculated. 
	    
	# The displacement feature is provided by the TrackDurationAnalyzer.
	    
	settings.addTrackAnalyzer(TrackDurationAnalyzer())
	    
	# Configure track filters - 
	# Track displacement must be above 100 pixels.
	    
	filter2 = FeatureFilter('TRACK_DISPLACEMENT', TrackDisp_filter, True)
	settings.addTrackFilter(filter2)
	    
	    
	#-------------------
	# Instantiate plugin
	#-------------------
	    
	trackmate = TrackMate(model, settings)
	       
	#--------
	# Process
	#--------
	    
	ok = trackmate.checkInput()
	if not ok:
	    sys.exit(str(trackmate.getErrorMessage()))
	    
	ok = trackmate.process()
	if not ok:
	    sys.exit(str(trackmate.getErrorMessage()))
	    
	       
	#----------------
	# Display results
	#----------------
	     
	selectionModel = SelectionModel(model)
	displayer =  HyperStackDisplayer(model, selectionModel, imp)
	displayer.render()
	displayer.refresh()
	    
	# Echo results with the logger we set at start:
	model.getLogger().log(str(model))
	print "Done"
	# The feature model, that stores edge and track features.
	fm = model.getFeatureModel()
	X = []
	Y= []
	T = []
	Track = []  
	for id in model.getTrackModel().trackIDs(True):
	   
	    # Fetch the track feature from the feature model.
	    v = fm.getTrackFeature(id, 'TRACK_MEAN_SPEED')
	    model.getLogger().log('')
	    model.getLogger().log('Track ' + str(id) + ': mean velocity = ' + str(v) + ' ' + model.getSpaceUnits() + '/' + model.getTimeUnits())
	       
	    track = model.getTrackModel().trackSpots(id)
	    for spot in track:
	        sid = spot.ID()
	        # Fetch spot features directly from spot. 
	        x=spot.getFeature('POSITION_X')
	        y=spot.getFeature('POSITION_Y')
	        t=spot.getFeature('FRAME')
	        q=spot.getFeature('QUALITY')
	        snr=spot.getFeature('SNR') 
	        mean=spot.getFeature('MEAN_INTENSITY')
	        X.append(x)
	        Y.append(y)
	        T.append(t)
	        Track.append(id)
	        #model.getLogger().log('\tspot ID = ' + str(sid)
	        #	+ ': x='+str(x)+', y='+str(y)+', t='+str(t)+
	        #	'q='+str(q) + ', snr='+str(snr) + ', mean = ' + str(mean))
	        
	results = izip_longest(Track,X,Y,T)
	header = izip_longest(['Track'], ['X'], ['Y'], ['T'])
   	if not os.path.exists(dir_output):  # create an output directory
   		os.makedirs(dir_output)
	with open(dir_output + file + '.csv', 'wb') as myFile:
	    # with open(dir_output + 'Velocity_Acceleration_' + filename + '.csv', 'wb') as myFile:
	    wr = csv.writer(myFile, delimiter=',')
	    for head in header:
	        wr.writerow(head)
	    for rows in results:
	        wr.writerow(rows)
	#imp.close()