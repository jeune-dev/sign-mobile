abstract class QuittanceLoyerEvent {}

class LoadQuittances extends QuittanceLoyerEvent {
  final int page;
  final int limit;
  LoadQuittances({this.page = 1, this.limit = 10});
}

class LoadMoreQuittances extends QuittanceLoyerEvent {}

class LoadQuittanceDetail extends QuittanceLoyerEvent {
  final String quittanceId;
  LoadQuittanceDetail(this.quittanceId);
}

class CreerQuittanceEvent extends QuittanceLoyerEvent {
  final Map<String, dynamic> data;
  CreerQuittanceEvent(this.data);
}

class TelechargerQuittanceEvent extends QuittanceLoyerEvent {
  final String quittanceId;
  TelechargerQuittanceEvent(this.quittanceId);
}

class ResetQuittanceState extends QuittanceLoyerEvent {}
