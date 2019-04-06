# ViconPupilIntegration

The purpose is to provide a step by step implementation of a PupilEyeTracker into a Vicon environment


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
