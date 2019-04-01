## ViconPupilIntegration

The purpose is to provide a step by step implementation of a PupilEyeTracker into a Vicon environment

### Algorithm
## Calibration
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
