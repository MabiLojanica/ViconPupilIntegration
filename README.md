# Vicon Pupil Integration for algorithmic gaze analysis

The purpose is to provide a step by step implementation of a PupilEyeTracker into a Vicon environment.
This readme contains three parts:  
**Part 1:** Setup for Vicon (Calibration, creating rigid body segments and tips for recording data).  
**Part 2:** Setup for Pupil (Attaching reflective markers to the glass, calibrating the position of the tracker in space and calibrating gaze)  
**Part 3:** Integration of movement data and gaze data. Here, measures from Vicon (movement data) and Pupil tracker (gaze data) are performed in Matlab. Follow the `integration.m` script to understand the calculations described here.  

![Main](https://i.imgur.com/5ConwjF.png)


## Part 1: Setup for Vicon
Pending.
## Part 2: Setup for Pupil
Pending. 
## Part 3: Integration of movement data and gaze data
To understand the calculations performed in this part, open `integration.m` file in the repository. The description here follows the sections of the code in the Matlab script.

### Section: Make inventory of data directory
#### Saving the data in the correct folder structure
This script is flexible to take data for only one participant or for several. In this section, Matlab makes a list of all the participants and all their trials to perform all subsequent calculations.  
First, the filepath of the folder where the script is needs to be specified. Second, the filepath to the folder where the data is stored needs to be specified (as `DataDir`).  
Requirement here: `DataDir` needs to be organized in [this structure](Pending).  
#### For each participant, for each trial
There are two main loops happening in the analysis. On a high level, analysis starts for the first participant. When finished, the second participant is loaded. Within each participant, all the trials are loaded. The calculation starts with the first trial, when finished it moves to the next. This is seen in the two `for` loops (Cycle through all participants; Cycle through all trials of each participant).  
Before the actual loops start, Matlab creates an inventory of all the `c3d` files (Vicon), the `csv`files (Raw pupil export) and the `mat` files (imported Pupil files).  
Check the following variables in the script: The variables `*Trialnames_cell` should always contain a cell array with all the trials of the currently loaded participant. 
### Section: Load and Organize Data
#### Handling the Vicon data
Pending.
#### Handling the Pupil data
Pending.

### Section: Preprocess Data
Pending

### Section: Calculations Body segments
Pending

### Section: Synchronization of the Pupil data and the Vicon data
Pending

### Section: Calculations of gaze Vector 
Pupil gaze data is stored as vectors in normalized space. In the [Pupil Documentation](https://docs.pupil-labs.com/#data-format), it is explained that the OpenGL convention is used. Normalized space is basically an imaginary cube, where the top right corner has coordinates [1 1] and the origin is at [0 0].  
To work with the data, they need to be transformed to whats called [spherical coordinates](https://en.wikipedia.org/wiki/Spherical_coordinate_system). For illustration, lets follow the illustration:  
![Spherical](https://i.imgur.com/iuPbUw7.png | width= 200)  
A point in 3D space can be described by three spherical components:  
- Its distance from the Origin, namely the Euclidean distance  
- The azimuth (Phi), which is the deviation in the horizontal plane, depicted with the blue circle segment
- The inclination (Theta), which is the deviation in the vertical plane, depicted with the red circle segment

In the script, the gaze data is loaded and then transformed into azimuth and inclination. These are equivalent to Yaw and Pitch in Euler angles](https://en.wikipedia.org/wiki/Aircraft_principal_axes). In the following, the Euler Naming convenctions (Yaw, Pitch, and Roll) are used.

This gives an understanding about how the eye is rotated in space relative to the calibration origin. To illustrate, use the following example:
![YawPitch](https://i.imgur.com/eRw62HM.png | height = 300)
The black star indicates the gaze calibration origin. This point has values of 0 for both Yaw and Pitch. As the gaze goes towards the right of the calibration cross, Yaw (blue) increases, while Pitch (red) decreases.

To work with this data, lets assume: At the beginning of each calibration, the participant has his head in a neutral position and the gaze directed to the center of the calibration cross. I assume that the gaze vector in this position is [0 0]. All the eye movements happening after the calibration will be seen as relative to this gaze origin. This is done by subtracting all values from the first value:  
`yaw = yaw - yaw(1,1);  
pitch = pitch - pitch(1,1);`

The result is the gaze Yaw and Pitch for each frame (Units: Degrees) relative to the first calibration frame, stored in `df_deg`.

#### Calculation of the position and rotation of the Pupil tracker in space








 

### Section: Calculations of Head Vector
















## Pupil data extraction
### Data format general
- Source: [Pupil Docs](https://docs.pupil-labs.com/#data-format)
- Pupil data format for gaze vectors are using normalized space
- Origin 0,0 at the bottom left and 1,1 at the top right. This is the OpenGL convention 
 
### Data format "gaze_positions.csv"
- `gaze_timestamp` are timestamps in seconds. The number is usually really high, since it is the computer clock since last start. A timestamp of 6000 means that the computer was last restarted 6000 seconds ago. From this column, only the difference between each timeframe is of interest.
- For recordings of 120 Hz, one would expect delta timestamps of 1/120 s = 0.0083
- Looking into the actual data, a delta of 0.0040 was found, indicating a necessary interpolation ([See graph](https://imgur.com/fYKoSV3))
 





## Algorithm
### Calibration
- Subject stands in steady position, eye centered on calibration marker
- Start Vicon capture
- Get rotation from rigid body on first frame. This will be baseline yaw, pitch, and roll for world cordinates
- Start Pupil capture
- Set rotation of first frames to 0 (yaw and pitch of the eye)
- For each frame: Add the yaw and pitch of the eye to the rigid body rotation












<!---
```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/soccerdaniel/ViconPupilIntegration/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://help.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out.

 and --->
