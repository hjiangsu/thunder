import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:lemmy_api_client/v3.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/enums/full_name_separator.dart';
import 'package:thunder/feed/utils/utils.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/shared/avatars/community_avatar.dart';
import 'package:thunder/shared/snackbar.dart';
import 'package:thunder/user/widgets/user_sidebar_activity.dart';
import 'package:thunder/user/widgets/user_sidebar_stats.dart';
import 'package:thunder/utils/instance.dart';

import '../../shared/common_markdown_body.dart';
import '../../thunder/bloc/thunder_bloc.dart';
import '../../utils/date_time.dart';
import '../bloc/user_bloc.dart';

const kSidebarWidthFactor = 0.8;

class UserSidebar extends StatefulWidget {
  final PersonView? userInfo;
  final List<CommunityModeratorView>? moderates;
  final bool isAccountUser;
  final List<PersonBlockView>? personBlocks;
  final BlockPersonResponse? blockedPerson;

  const UserSidebar({
    super.key,
    required this.userInfo,
    required this.moderates,
    required this.isAccountUser,
    this.personBlocks,
    this.blockedPerson,
  });

  @override
  State<UserSidebar> createState() => _UserSidebarState();
}

class _UserSidebarState extends State<UserSidebar> {
  final ScrollController _scrollController = ScrollController();
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    //custom stats
    final totalContributions = (widget.userInfo!.counts.postCount + widget.userInfo!.counts.commentCount);
    final totalScore = ((widget.userInfo!.counts.postScore?.toInt() ?? 0) + (widget.userInfo!.counts.commentScore?.toInt() ?? 0));
    Duration accountAge = DateTime.now().difference(widget.userInfo!.person.published);
    final accountAgeMonths = ((accountAge.inDays) / 30).toDouble();
    final num postsPerMonth;
    final num commentsPerMonth;
    final totalContributionsPerMonth = (totalContributions / accountAgeMonths);
    final ThunderState state = context.read<ThunderBloc>().state;
    bool scoreCounters = state.scoreCounters;

    if (widget.userInfo!.counts.postCount != 0) {
      postsPerMonth = (widget.userInfo!.counts.postCount / accountAgeMonths);
    } else {
      postsPerMonth = 0;
    }

    if ((widget.userInfo!.counts.commentCount).toInt() != 0) {
      commentsPerMonth = (widget.userInfo!.counts.commentCount / accountAgeMonths);
    } else {
      commentsPerMonth = 0;
    }

    bool isLoggedIn = context.read<AuthBloc>().state.isLoggedIn;

    if (widget.personBlocks != null) {
      for (var user in widget.personBlocks!) {
        if (user.person.id == widget.userInfo!.person.id) {
          isBlocked = true;
        }
      }
    }

    if (widget.blockedPerson != null) {
      isBlocked = widget.blockedPerson!.blocked;
    }

    return Container(
      alignment: Alignment.topRight,
      child: FractionallySizedBox(
        widthFactor: kSidebarWidthFactor,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(Colors.black.withOpacity(0.25), theme.colorScheme.background),
                          theme.colorScheme.background,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.background,
                    ),
                  ),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        end: Alignment.topCenter,
                        begin: Alignment.bottomCenter,
                        colors: [
                          Color.alphaBlend(Colors.black.withOpacity(0.25), theme.colorScheme.background),
                          theme.colorScheme.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    child: !widget.isAccountUser
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  left: 12,
                                  right: 12,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isLoggedIn
                                            ? () {
                                                HapticFeedback.heavyImpact();
                                                hideSnackbar(context);
                                                context.read<UserBloc>().add(
                                                      BlockUserEvent(
                                                        personId: widget.userInfo!.person.id,
                                                        blocked: isBlocked == true ? false : true,
                                                      ),
                                                    );
                                              }
                                            : null,
                                        style: TextButton.styleFrom(
                                          fixedSize: const Size.fromHeight(40),
                                          foregroundColor: Colors.redAccent,
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isBlocked == true ? Icons.undo_rounded : Icons.block,
                                              semanticLabel: isBlocked == true ? 'Unblock User' : 'Block User',
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              isBlocked == true ? 'Unblock User' : 'Block User',
                                              style: const TextStyle(
                                                color: null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          )
                        : null,
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6.0, bottom: 6),
                                child: Row(children: [
                                  Text("Bio"),
                                  Expanded(
                                    child: Divider(
                                      height: 5,
                                      thickness: 2,
                                      indent: 15,
                                      endIndent: 5,
                                    ),
                                  ),
                                ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8,
                                  bottom: 8,
                                ),
                                child: Material(
                                  child: CommonMarkdownBody(
                                    body: widget.userInfo?.person.bio ?? 'Nothing here. This user has not written a bio.',
                                    imageMaxWidth: (kSidebarWidthFactor - 0.1) * MediaQuery.of(context).size.width,
                                    allowHorizontalTranslation: false,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 10.0, bottom: 6),
                                child: Row(children: [
                                  Text("Stats"),
                                  Expanded(
                                    child: Divider(
                                      height: 5,
                                      thickness: 2,
                                      indent: 15,
                                      endIndent: 5,
                                    ),
                                  ),
                                ]),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3.0),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                                        child: Icon(
                                          Icons.cake_rounded,
                                          size: 18,
                                          color: theme.colorScheme.onBackground.withOpacity(0.65),
                                        ),
                                      ),
                                      // TODO Make this use device date format
                                      Text(
                                        'Joined ${DateFormat.yMMMMd().format(widget.userInfo!.person.published)} · ${formatTimeToString(dateTime: widget.userInfo!.person.published.toIso8601String())} ago',
                                        style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.65)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3.0),
                                  UserSidebarStats(
                                    icon: Icons.wysiwyg_rounded,
                                    label: ' Posts',
                                    metric: NumberFormat("#,###,###,###").format(widget.userInfo!.counts.postCount),
                                    scoreLabel: widget.userInfo!.counts.postScore == null ? 'No score available' : ' Score',
                                    scoreMetric: widget.userInfo!.counts.postScore == null ? '' : NumberFormat("#,###,###,###").format(widget.userInfo!.counts.postScore),
                                  ),
                                  const SizedBox(height: 3.0),
                                  UserSidebarStats(
                                    icon: Icons.chat_rounded,
                                    label: ' Comments',
                                    metric: NumberFormat("#,###,###,###").format(widget.userInfo!.counts.commentCount),
                                    scoreLabel: widget.userInfo!.counts.commentScore == null ? 'No score available' : ' Score',
                                    scoreMetric: widget.userInfo!.counts.commentScore == null ? '' : NumberFormat("#,###,###,###").format(widget.userInfo!.counts.commentScore),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Visibility(
                                      visible: scoreCounters,
                                      child: UserSidebarActivity(
                                        icon: Icons.celebration_rounded,
                                        scoreLabel: totalScore == 0 ? 'Score not available' : ' Total Score',
                                        scoreMetric: totalScore == 0 ? '' : NumberFormat("#,###,###,###").format(totalScore),
                                      )),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 12.0, bottom: 6),
                                child: Row(children: [
                                  Text("Activity"),
                                  Expanded(
                                    child: Divider(
                                      height: 5,
                                      thickness: 2,
                                      indent: 15,
                                      endIndent: 5,
                                    ),
                                  ),
                                ]),
                              ),
                              UserSidebarActivity(
                                icon: Icons.wysiwyg_rounded,
                                scoreLabel: ' Average Posts/mo',
                                scoreMetric: NumberFormat("#,###,###,###").format(postsPerMonth),
                              ),
                              const SizedBox(height: 3.0),
                              UserSidebarActivity(
                                icon: Icons.chat_rounded,
                                scoreLabel: ' Average Comments/mo',
                                scoreMetric: NumberFormat("#,###,###,###").format(commentsPerMonth),
                              ),
                              const SizedBox(height: 3.0),
                              UserSidebarActivity(
                                icon: Icons.score_rounded,
                                scoreLabel: ' Average Contributions/mo',
                                scoreMetric: NumberFormat("#,###,###,###").format(totalContributionsPerMonth),
                              ),
                              Container(
                                child: widget.moderates!.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 16.0, bottom: 8),
                                            child: Row(children: [
                                              Text("Moderates"),
                                              Expanded(
                                                child: Divider(
                                                  height: 5,
                                                  thickness: 2,
                                                  indent: 15,
                                                  endIndent: 5,
                                                ),
                                              ),
                                            ]),
                                          ),
                                          Column(
                                            children: [
                                              for (var mods in widget.moderates!)
                                                Material(
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(50),
                                                    onTap: () => navigateToFeedPage(context, feedType: FeedType.community, communityId: mods.community.id),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Row(
                                                        children: [
                                                          CommunityAvatar(community: mods.community, radius: 20.0),
                                                          const SizedBox(width: 16.0),
                                                          Expanded(
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  mods.community.title,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                                  style: const TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 16,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  generateCommunityFullName(context, mods.community.name, fetchInstanceNameFromUrl(mods.community.actorId)),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                                                                    fontSize: 13,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 128,
                        )
                      ],
                    ),
                  ),
                  Container(
                    child: widget.isAccountUser
                        ? Column(
                            children: [
                              const Divider(
                                height: 0,
                                thickness: 2,
                              ),
                              const SizedBox(height: 10.0),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0, left: 12, right: 12),
                                child: ElevatedButton(
                                  onPressed: null /*() {
                              HapticFeedback.mediumImpact();
                            }*/
                                  ,
                                  style: TextButton.styleFrom(
                                    fixedSize: const Size.fromHeight(40),
                                    foregroundColor: null,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        semanticLabel: 'Edit Profile',
                                      ),
                                      SizedBox(width: 4.0),
                                      Text(
                                        'Edit Profile',
                                        style: TextStyle(
                                          color: null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
