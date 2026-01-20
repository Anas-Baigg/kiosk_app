class DailyFinance {
  final DateTime date;
  final double cashTotal;
  final double cardTotal;
  final double tillBalance;

  DailyFinance({
    required this.date,
    required this.cashTotal,
    required this.cardTotal,
    required this.tillBalance,
  });
}
