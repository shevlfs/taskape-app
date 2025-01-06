//
//  fontSetup.swift
//  taskape
//
//  Created by shevlfs on 1/6/25.
//

import SwiftUI

extension Font {
   static let pathwayBlack = Font.custom("PathwayExtreme-Black", size: UIFont.systemFontSize)
   static let pathwayBold = Font.custom("PathwayExtreme-Bold", size: UIFont.systemFontSize)
   static let pathwayExtraBold = Font.custom("PathwayExtreme-ExtraBold", size: UIFont.systemFontSize)
   static let pathwayExtraLight = Font.custom("PathwayExtreme-ExtraLight", size: UIFont.systemFontSize)
   static let pathwayLight = Font.custom("PathwayExtreme-Light", size: UIFont.systemFontSize)
   static let pathwayMedium = Font.custom("PathwayExtreme-Medium", size: UIFont.systemFontSize)
   static let pathwayRegular = Font.custom("PathwayExtreme-Regular", size: UIFont.systemFontSize)
   static let pathwaySemiBold = Font.custom("PathwayExtreme-SemiBold", size: UIFont.systemFontSize)
   static let pathwayThin = Font.custom("PathwayExtreme-Thin", size: UIFont.systemFontSize)

   static let pathwayBlackItalic = Font.custom("PathwayExtreme-BlackItalic", size: UIFont.systemFontSize)
   static let pathwayBoldItalic = Font.custom("PathwayExtreme-BoldItalic", size: UIFont.systemFontSize)
   static let pathwayExtraBoldItalic = Font.custom("PathwayExtreme-ExtBdIta", size: UIFont.systemFontSize)
   static let pathwayExtraLightItalic = Font.custom("PathwayExtreme-ExtLtIta", size: UIFont.systemFontSize)
   static let pathwayLightItalic = Font.custom("PathwayExtreme-LightItalic", size: UIFont.systemFontSize)
   static let pathwayMediumItalic = Font.custom("PathwayExtreme-MediumItalic", size: UIFont.systemFontSize)
   static let pathwayItalic = Font.custom("PathwayExtreme-Italic", size: UIFont.systemFontSize)
   static let pathwaySemiBoldItalic = Font.custom("PathwayExtreme-SemiBoldItalic", size: UIFont.systemFontSize)
   static let pathwayThinItalic = Font.custom("PathwayExtreme-ThinItalic", size: UIFont.systemFontSize)

   // Condensed styles
   static let pathwayBlackCondensed = Font.custom("PathwayExtreme-BlackCondensed", size: UIFont.systemFontSize)
   static let pathwayBoldCondensed = Font.custom("PathwayExtreme-BoldCondensed", size: UIFont.systemFontSize)
   static let pathwayExtraBoldCondensed = Font.custom("PathwayExtreme-ExtBdCond", size: UIFont.systemFontSize)
   static let pathwayExtraLightCondensed = Font.custom("PathwayExtreme-ExtLtCond", size: UIFont.systemFontSize)
   static let pathwayLightCondensed = Font.custom("PathwayExtreme-LigthCondensed", size: UIFont.systemFontSize)
   static let pathwayMediumCondensed = Font.custom("PathwayExtreme-MedCond", size: UIFont.systemFontSize)
   static let pathwayCondensed = Font.custom("PathwayExtreme-Condensed", size: UIFont.systemFontSize)
   static let pathwaySemiBoldCondensed = Font.custom("PathwayExtreme-SemBdCond", size: UIFont.systemFontSize)
   static let pathwayThinCondensed = Font.custom("PathwayExtreme-ThinCondensed", size: UIFont.systemFontSize)

   static let pathwayBlackCondensedItalic = Font.custom("PathwayExtreme-BlackCondIta", size: UIFont.systemFontSize)
   static let pathwayBoldCondensedItalic = Font.custom("PathwayExtreme-BoldCondIta", size: UIFont.systemFontSize)
   static let pathwayExtraBoldCondensedItalic = Font.custom("PathwayExtreme-ExtBdCondIta", size: UIFont.systemFontSize)
   static let pathwayExtraLightCondensedItalic = Font.custom("PathwayExtreme-ExtLtCondIta", size: UIFont.systemFontSize)
   static let pathwayLightCondensedItalic = Font.custom("PathwayExtreme-LightCondIta", size: UIFont.systemFontSize)
   static let pathwayMediumCondensedItalic = Font.custom("PathwayExtreme-MedCondIta", size: UIFont.systemFontSize)
   static let pathwayCondensedItalic = Font.custom("PathwayExtreme-CondIta", size: UIFont.systemFontSize)
   static let pathwaySemiBoldCondensedItalic = Font.custom("PathwayExtreme-SemBdCondIta", size: UIFont.systemFontSize)
   static let pathwayThinCondensedItalic = Font.custom("PathwayExtreme-ThinCondIta", size: UIFont.systemFontSize)

   static func pathway(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-Regular", size: size)
   }

   static func pathwayBold(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-Bold", size: size)
   }

   static func pathwayCondensed(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-Condensed", size: size)
   }

   static func pathwayBoldCondensed(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-BoldCondensed", size: size)
   }

   static func pathwayItalic(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-Italic", size: size)
   }

   static func pathwayBoldItalic(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-BoldItalic", size: size)
   }

   static func pathwayCondensedItalic(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-CondIta", size: size)
   }

   static func pathwayBoldCondensedItalic(_ size: CGFloat) -> Font {
       .custom("PathwayExtreme-BoldCondIta", size: size)
   }
}

struct DefaultFontModifier: ViewModifier {
   func body(content: Content) -> some View {
       content.font(.pathwayRegular)
   }
}

extension View {
   func setDefaultFont() -> some View {
       modifier(DefaultFontModifier())
   }
}
