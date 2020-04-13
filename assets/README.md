# Green Assets

## IMPORTANT NOTE:

On some older Android versions (<= 21) XML icons with a "fillType" have issues with dynamic theme colors and are rendered in black. If this happens you can either ["flatten the image"](https://stackoverflow.com/questions/41188944/use-filltype-evenodd-on-android-21) (never personally tested) or convert them using [Shape Shifter](https://shapeshifter.design/). You can import an XML icon that have the "fillType", select the path in the bottom left menu, change the fillType to "nonZero" using the toolbar on the right and then re-export it as an XML "Vector Drawable". This usually removes the "fillType" attr entirely.