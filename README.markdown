#**MapAdjust** - *What happens after Gephi?*

- **author**: Alexis Jacomy, *alexis dot jacomy at gmail dot com*

##I. Introduction

This Flash application is a tool to help to display geocoded graphs with a SVG background map in GexfWalker.

##II. How to use it

You need first to have installed on your computer the Adobe Flash Player (if you can watch videos on YouTube, then it is already done). Also, you need a GEXF encoded graph file, with a layout. Then:

1. Download the last stable version in the [Downloads](http://github.com/jacomyal/MapAdjust/downloads) section of this GitHub homepage.
2. Change in **mapAdjust_demo/simple_example.html** the values of **svgPath** and **gexfPath** (respectively the SVG file path and the GEXF file path)
3. Open with your web browser the file **mapAdjust_demo/simple_example.html**
4. Calibrate your map with your graph by moving and scaling the background map
5. Add in your GEXF graph file the four following attributes to the **graph** XML tag, with the values displayed in MapAdjust (top-left of the application): **backgroundx**, **backgroundy**, **backgroundxratio** and **backgroundxratio**.
6. Use GexfWalker as described on [the main page of this project](http://www.github.com/jacomyal/GexfWalker#readme), with just adding '**&svgPath=[the path of your SVG background map]**' just after the '**gexfPath**' in your HTML 'object' element (at two different places, if everything is normal).

##III. Other information

This tool has just been developed to calibrate the maps (or any SVG background you want) with a GEXF encoded graph for GexfWalker. You can also find a tutorial explaining with an example how to use it [here](http://ofnodesandedges.com/display-geocoded-graphs-with-gexfwalker/).