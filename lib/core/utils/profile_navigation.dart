import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Routes name/avatar taps to the correct profile: people or organization.
class ProfileNavigation {
  ProfileNavigation._();

  static bool isOrganization({
    bool? isBusinessPagePost,
    String? accountType,
    String? organizationId,
  }) {
    if (isBusinessPagePost == true) return true;
    if (accountType?.toLowerCase() == 'business') return true;
    final orgId = organizationId?.trim();
    return orgId != null && orgId.isNotEmpty;
  }

  static String? organizationIdentifier({
    String? organizationId,
    String? organizationSlug,
  }) {
    final slug = organizationSlug?.trim();
    if (slug != null && slug.isNotEmpty) return slug;
    final id = organizationId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  static void openUser(
    BuildContext context,
    String? userId, {
    bool viewAsPublic = false,
  }) {
    final id = userId?.trim();
    if (id == null || id.isEmpty) return;
    SVProfileFragment(userId: id, viewAsPublic: viewAsPublic).launch(context);
  }

  static void openOrganization(BuildContext context, String identifier) {
    final id = identifier.trim();
    if (id.isEmpty) return;
    OrganizationProfileScreen(identifier: id).launch(context);
  }

  /// Opens a people or business profile from loose fields.
  static void open(
    BuildContext context, {
    String? userId,
    String? organizationId,
    String? organizationSlug,
    bool? isBusinessPagePost,
    String? accountType,
    bool viewAsPublic = false,
  }) {
    if (isOrganization(
      isBusinessPagePost: isBusinessPagePost,
      accountType: accountType,
      organizationId: organizationId,
    )) {
      final identifier = organizationIdentifier(
        organizationId: organizationId,
        organizationSlug: organizationSlug,
      );
      if (identifier != null) {
        openOrganization(context, identifier);
        return;
      }
    }
    openUser(context, userId, viewAsPublic: viewAsPublic);
  }

  static String? _feedOrganizationId(FeedItem item) =>
      item.str('organizationId') ?? item.str('organization_id');

  static String? _feedOrganizationSlug(FeedItem item) =>
      item.str('organizationSlug') ?? item.str('organization_slug');

  static bool _feedIsBusiness(FeedItem item) {
    if (item.flag('isBusinessPagePost') ||
        item.flag('is_business_page_post')) {
      return true;
    }
    final accountType =
        item.str('accountType') ?? item.str('account_type');
    if (accountType?.toLowerCase() == 'business') return true;
    final orgId = _feedOrganizationId(item);
    if (orgId != null && orgId.isNotEmpty) return true;
    final slug = _feedOrganizationSlug(item);
    return slug != null && slug.isNotEmpty;
  }

  static void openFromFeedItem(BuildContext context, FeedItem item) {
    final isBusiness = _feedIsBusiness(item);
    open(
      context,
      userId: isBusiness ? null : (item.authorId ?? item.str('authorId')),
      organizationId: _feedOrganizationId(item),
      organizationSlug: _feedOrganizationSlug(item),
      isBusinessPagePost: isBusiness,
      accountType:
          item.str('accountType') ?? item.str('account_type') ?? (isBusiness ? 'business' : null),
    );
  }

  static void openFromPost(
    BuildContext context,
    Post post, {
    bool viewAsPublic = false,
  }) {
    final isBusiness = post.isBusinessPagePost == true ||
        post.accountType?.toLowerCase() == 'business' ||
        (post.organizationId != null && post.organizationId!.isNotEmpty);
    open(
      context,
      userId: isBusiness ? null : (post.userId ?? post.user?.id),
      organizationId: post.organizationId,
      organizationSlug: post.organizationSlug,
      isBusinessPagePost: isBusiness,
      accountType: post.accountType ?? (isBusiness ? 'business' : null),
      viewAsPublic: viewAsPublic,
    );
  }

  static void openFromMap(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final type = data['type']?.toString().toLowerCase();
    if (type == 'organization' ||
        type == 'business' ||
        data['is_organization'] == true) {
      final identifier = organizationIdentifier(
        organizationId: data['id']?.toString() ??
            data['organization_id']?.toString() ??
            data['organizationId']?.toString(),
        organizationSlug: data['slug']?.toString() ??
            data['organization_slug']?.toString(),
      );
      if (identifier != null) {
        openOrganization(context, identifier);
        return;
      }
    }

    open(
      context,
      userId: data['id']?.toString() ??
          data['user_id']?.toString() ??
          data['userId']?.toString(),
      organizationId: data['organization_id']?.toString() ??
          data['organizationId']?.toString(),
      organizationSlug: data['organization_slug']?.toString() ??
          data['organizationSlug']?.toString() ??
          data['slug']?.toString(),
      isBusinessPagePost: data['is_business_page_post'] == true ||
          data['isBusinessPagePost'] == true,
      accountType: data['account_type']?.toString() ??
          data['accountType']?.toString(),
    );
  }
}
