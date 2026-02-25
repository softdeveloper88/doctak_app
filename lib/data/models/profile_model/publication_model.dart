/// Model for Research & Publications (maps to research_and_publications table)
class PublicationModel {
  int? id;
  String? userId;
  String? title;
  String? journalName;
  String? publicationDate;
  String? coAuthor;
  String? abstract_;
  String? keywords;
  String? impactFactor;
  String? citations;
  String? doiLink;
  String? privacy;
  String? createdAt;
  String? updatedAt;

  PublicationModel({
    this.id,
    this.userId,
    this.title,
    this.journalName,
    this.publicationDate,
    this.coAuthor,
    this.abstract_,
    this.keywords,
    this.impactFactor,
    this.citations,
    this.doiLink,
    this.privacy,
    this.createdAt,
    this.updatedAt,
  });

  factory PublicationModel.fromJson(Map<String, dynamic> json) {
    return PublicationModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString(),
      title: json['title'] as String?,
      journalName: json['journal_name'] as String?,
      publicationDate: json['publication_date'] as String?,
      coAuthor: json['co_author'] as String?,
      abstract_: json['abstract'] as String?,
      keywords: json['keywords'] as String?,
      impactFactor: json['impact_factor'] as String?,
      citations: json['citations'] as String?,
      doiLink: json['doi_link'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'journal_name': journalName,
      'publication_date': publicationDate,
      'co_author': coAuthor,
      'abstract': abstract_,
      'keywords': keywords,
      'impact_factor': impactFactor,
      'citations': citations,
      'doi_link': doiLink,
      'privacy': privacy,
    };
  }
}
