syntax match githubNotifMark /^●/ nextgroup=githubNotifFullName skipwhite
syntax match githubNotifFullName /[[:alnum:].@:\/\-~]\+/ contained nextgroup=githubNotifTitle skipwhite
syntax region githubNotifTitle start=/  / end=/  / contained nextgroup=githubNotifReason skipwhite
syntax keyword githubNotifReason assign author comment invitation manual mention review_requested security_alert state_change subscribed team_mention contained nextgroup=githubNotifType skipwhite
syntax keyword githubNotifType PullRequest Issue contained skipwhite

highlight link githubNotifMark Title
highlight link githubNotifFullName Label
highlight link githubNotifTitle Title
