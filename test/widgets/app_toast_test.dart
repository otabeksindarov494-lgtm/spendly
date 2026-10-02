import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendly/theme/app_theme.dart';
import 'package:spendly/widgets/common/app_toast.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('toast ekranning yuqori qismida chiqadi', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await pumpHost(tester);
    AppToast.show(context, 'Saqlandi');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    final Finder toast = find.text('Saqlandi');
    expect(toast, findsOneWidget);
    final double screenHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio;
    expect(tester.getTopLeft(toast).dy, lessThan(screenHeight / 3));

    // Vaqti tugagach o'zi yo'qoladi.
    await tester.pump(AppToast.duration);
    await tester.pumpAndSettle();
    expect(find.text('Saqlandi'), findsNothing);
  });

  testWidgets('yangi toast eskisini almashtiradi', (WidgetTester tester) async {
    final BuildContext context = await pumpHost(tester);
    AppToast.show(context, 'Birinchi');
    await tester.pump();
    AppToast.show(context, 'Ikkinchi', isError: true);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Birinchi'), findsNothing);
    expect(find.text('Ikkinchi'), findsOneWidget);

    await tester.pump(AppToast.duration);
    await tester.pumpAndSettle();
  });
}
