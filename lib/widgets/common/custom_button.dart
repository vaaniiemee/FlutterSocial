import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? icon;
  final Widget? child;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = AppConstants.buttonHeightLarge,
    this.icon,
    this.child,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = AppConstants.borderRadiusMedium,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    
    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      
      switch (type) {
        case ButtonType.primary:
          return isDisabled ? AppConstants.textTertiary : AppConstants.primaryColor;
        case ButtonType.secondary:
          return isDisabled ? AppConstants.textTertiary : AppConstants.secondaryColor;
        case ButtonType.outline:
        case ButtonType.text:
          return Colors.transparent;
      }
    }
    
    Color getTextColor() {
      if (textColor != null) return textColor!;
      
      switch (type) {
        case ButtonType.primary:
        case ButtonType.secondary:
          return Colors.white;
        case ButtonType.outline:
          return isDisabled ? AppConstants.textTertiary : AppConstants.primaryColor;
        case ButtonType.text:
          return isDisabled ? AppConstants.textTertiary : AppConstants.primaryColor;
      }
    }
    
    Border? getBorder() {
      switch (type) {
        case ButtonType.outline:
          return Border.all(
            color: isDisabled ? AppConstants.textTertiary : AppConstants.primaryColor,
            width: 1,
          );
        case ButtonType.text:
          return null;
        default:
          return null;
      }
    }

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
            ),
          )
        : child ?? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppConstants.iconSizeMedium),
                const SizedBox(width: AppConstants.spacingSmall),
              ],
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    fontWeight: AppConstants.fontWeightSemiBold,
                    color: getTextColor(),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    Widget button = type == ButtonType.text
          ? TextButton(
              onPressed: isDisabled ? null : onPressed,
              style: TextButton.styleFrom(
                foregroundColor: getTextColor(),
                padding: padding ?? const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMedium,
                  vertical: AppConstants.spacingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isDisabled ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: getBackgroundColor(),
                foregroundColor: getTextColor(),
                elevation: type == ButtonType.outline ? 0 : 2,
                shadowColor: AppConstants.primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  side: getBorder()?.left ?? BorderSide.none,
                ),
                padding: padding ?? const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLarge,
                  vertical: AppConstants.spacingMedium,
                ),
              ),
              child: buttonChild,
            );

    if (isFullWidth) {
      return SizedBox(
        height: height,
        child: button,
      );
    } else {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }
  }
}
