// How small a thing a five-year-old can be asked to hit.
//
// The platform minimums are written for adults: Apple asks for 44 points,
// Material for 48. On the iPad this is played on, 1180 logical pixels span
// about 247mm, so a pixel is roughly 0.21mm and 44 points is about 9mm.
// Studies of touch accuracy in young children put the comfortable floor
// nearer 12mm, and the engagement plan says the same thing in plainer words:
// "large tap targets; motor skills are still developing."
//
// 60 logical pixels is about 12.6mm on that screen. It is a floor, not a
// target size - most things a child taps here are creatures and shapes drawn
// at 120 to 150, and they should stay that way.
//
// Note that this is about the *hit area*, which does not have to be the
// drawn area. The habitat's sticks are the case that prompted the number: a
// stick is 28 pixels thick because that is the proportion the round and the
// lesson and the picker card all draw, and making it fatter to be tappable
// would have changed a shape three other things depend on. Its touch box is
// padded out instead, and the bar still looks like a stick.

/// The smallest hit area a child may be asked to hit accurately.
const double kMinTouchTarget = 60;
