import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services
pragma Singleton

Item {
    id: githubService

    property string username: SettingsService.githubUsername
    property string token: SettingsService.githubToken
    property bool hasToken: false
    property string avatarUrl: ""
    property string fullName: ""
    property string bio: ""
    property string location: ""
    property int publicRepos: 0
    property int privateRepos: 0
    property int followers: 0
    property int totalStars: 0
    property int totalForks: 0
    property string topRepoName: "..."
    property string topRepoDesc: ""
    property int topRepoStars: 0
    property int topRepoForks: 0
    property string topRepoLang: ""
    property string joinedDate: "..."
    property int totalCommits: 0
    property string topLanguage: "None"
    property bool isFetching: false
    property var contributionData: []
    property var repos: []
    property string tokenStatus: "none"   // none, valid, invalid, other_user, error, unknown
    property string tokenUser: ""
    property string errorKey: ""
    property int openPRs: 0
    property int openIssues: 0
    property int rateRemaining: -1
    property int rateLimit: -1
    readonly property string errorMessage: {
        switch (errorKey) {
        case "":
            return "";
        case "network": return "No connection to GitHub";
        case "rate_limited": return "GitHub rate limit reached" + (hasToken ? "" : " - add a token in Settings > Integrations");
        case "not_found": return "User not found";
        case "bad_token": return "Token was rejected";
        case "forbidden": return "GitHub denied the request";
        default: return "GitHub error (" + errorKey + ")";
        }
    }
    readonly property string tokenMessage: {
        switch (tokenStatus) {
        case "valid": return "Token valid" + (tokenUser ? " (" + tokenUser + ")" : "");
        case "invalid": return "Token invalid or expired";
        case "other_user": return "Token belongs to " + tokenUser + ", showing public data only";
        case "error": return "Could not verify token";
        default: return "";
        }
    }

    function getCachedAvatarPath(user) {
        let clean = ("" + user).replace(/[^a-zA-Z0-9_\-]/g, "").trim();
        return clean !== "" ? (Quickshell.env("HOME") + "/.cache/quickshell/github_avatar_" + clean + ".png") : (Quickshell.env("HOME") + "/.cache/quickshell/github_avatar.png");
    }

    function fetchData() {
        debounceTimer.restart();
    }

    function getCleanToken() {
        if (!githubService.token)
            return "";

        return ("" + githubService.token).replace(/[\r\n\t\x00-\x1f\x7f-\xff\s]/g, "").trim();
    }

    function executeFetch() {
        let user = ("" + githubService.username).replace(/[\r\n\t\x00-\x1f\x7f-\xff\s]/g, "").trim();
        if (user === "") {
            githubService.hasToken = false;
            githubService.avatarUrl = "";
            githubService.fullName = "";
            githubService.bio = "";
            githubService.location = "";
            githubService.publicRepos = 0;
            githubService.privateRepos = 0;
            githubService.followers = 0;
            githubService.joinedDate = "...";
            githubService.totalStars = 0;
            githubService.totalForks = 0;
            githubService.topRepoName = "...";
            githubService.topRepoDesc = "";
            githubService.topRepoStars = 0;
            githubService.topRepoForks = 0;
            githubService.topRepoLang = "";
            githubService.topLanguage = "None";
            githubService.totalCommits = 0;
            githubService.contributionData = [];
            githubService.repos = [];
            githubService.tokenStatus = "none";
            githubService.tokenUser = "";
            githubService.errorKey = "";
            githubService.openPRs = 0;
            githubService.openIssues = 0;
            githubService.rateRemaining = -1;
            githubService.rateLimit = -1;
            return ;
        }
        githubService.isFetching = true;
        fetchInfoProc.running = false;
        fetchInfoProc.running = true;
        fetchContributions(user);
    }

    function applyProfileData(profile, avatarPath) {
        if (!profile || !profile.login)
            return ;

        if (avatarPath) {
            githubService.avatarUrl = "file://" + avatarPath;
        } else {
            let localPath = getCachedAvatarPath(profile.login || githubService.username);
            githubService.avatarUrl = "file://" + localPath;
        }
        githubService.fullName = profile.name || "";
        githubService.bio = profile.bio || "";
        githubService.location = profile.location || "";
        githubService.publicRepos = profile.public_repos || 0;
        githubService.followers = profile.followers || 0;
        if (profile.created_at) {
            let date = new Date(profile.created_at);
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            githubService.joinedDate = months[date.getMonth()] + " " + date.getFullYear();
        }
    }

    function applyReposData(repos) {
        if (!Array.isArray(repos))
            return ;

        let starsSum = 0;
        let forksSum = 0;
        let best = null;
        let privateCount = 0;
        let langCounts = {};
        for (let i = 0; i < repos.length; i++) {
            let r = repos[i];
            if (!r)
                continue;

            starsSum += r.stars || 0;
            forksSum += r.forks || 0;
            if (r.private)
                privateCount++;

            if (!best || (r.stars || 0) > (best.stars || 0))
                best = r;

            if (r.language)
                langCounts[r.language] = (langCounts[r.language] || 0) + 1;

        }
        githubService.repos = repos;
        githubService.totalStars = starsSum;
        githubService.totalForks = forksSum;
        githubService.topRepoName = best ? best.name : "None";
        githubService.topRepoDesc = best ? (best.description || "") : "";
        githubService.topRepoStars = best ? (best.stars || 0) : 0;
        githubService.topRepoForks = best ? (best.forks || 0) : 0;
        githubService.topRepoLang = best ? (best.language || "") : "";
        if (githubService.hasToken && githubService.privateRepos === 0)
            githubService.privateRepos = privateCount;

        let mostLang = "None";
        let maxLangCount = 0;
        for (let lang in langCounts) {
            if (langCounts[lang] > maxLangCount) {
                maxLangCount = langCounts[lang];
                mostLang = lang;
            }
        }
        githubService.topLanguage = mostLang;
    }

    function fetchContributions(user) {
        contribProc.running = false;
        contribProc.running = true;
    }

    function checkFetchingComplete() {
        fetchTimer.restart();
    }

    Component.onCompleted: {
        if (githubService.username !== "")
            githubService.avatarUrl = "file://" + getCachedAvatarPath(githubService.username);

    }
    onUsernameChanged: {
        if (githubService.username !== "")
            githubService.avatarUrl = "file://" + getCachedAvatarPath(githubService.username);
        else
            githubService.avatarUrl = "";
        fetchData();
    }
    onTokenChanged: fetchData()

    Process {
        id: fetchInfoProc

        // The token travels through the environment instead of argv so it never
        // appears in process listings or /proc/<pid>/cmdline.
        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_github_info.py", ("" + githubService.username).trim()]
        environment: ({
            "MINFLAIR_GITHUB_TOKEN": githubService.getCleanToken()
        })
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                githubService.errorKey = "network";
                checkFetchingComplete();
                return ;
            }
            try {
                let parsed = JSON.parse(fetchInfoOutput.text);
                githubService.errorKey = parsed.error || "";
                githubService.tokenStatus = parsed.tokenStatus || "none";
                githubService.tokenUser = parsed.tokenUser || "";
                githubService.hasToken = parsed.hasToken === true;
                if (parsed.rate) {
                    githubService.rateRemaining = parsed.rate.remaining !== undefined ? parsed.rate.remaining : -1;
                    githubService.rateLimit = parsed.rate.limit !== undefined ? parsed.rate.limit : -1;
                }
                if (parsed.profile) {
                    applyProfileData(parsed.profile, parsed.avatar_path);
                    githubService.privateRepos = githubService.hasToken ? (parsed.profile.total_private_repos || parsed.profile.owned_private_repos || 0) : 0;
                }
                if (parsed.repos)
                    applyReposData(parsed.repos);

                githubService.totalCommits = (parsed.commits && parsed.commits.total_count !== undefined) ? parsed.commits.total_count : 0;
                githubService.openPRs = parsed.openPRs || 0;
                githubService.openIssues = parsed.openIssues || 0;
            } catch (e) {
                githubService.errorKey = "parse";
                console.error("Github fetch error: " + e);
            }
            checkFetchingComplete();
        }

        stdout: StdioCollector {
            id: fetchInfoOutput
        }

    }

    Process {
        id: contribProc

        // The token travels through the environment instead of argv so it never
        // appears in process listings or /proc/<pid>/cmdline.
        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_github_contributions.py", ("" + githubService.username).trim()]
        environment: ({
            "MINFLAIR_GITHUB_TOKEN": githubService.getCleanToken()
        })
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    let parsed = JSON.parse(contribOutput.text);
                    if (Array.isArray(parsed) && parsed.length > 0)
                        githubService.contributionData = parsed;

                } catch (e) {
                    console.error("Contributions parse error: " + e);
                }
            }
            checkFetchingComplete();
        }

        stdout: StdioCollector {
            id: contribOutput
        }

    }

    Timer {
        id: debounceTimer

        interval: 200
        repeat: false
        onTriggered: githubService.executeFetch()
    }

    Timer {
        id: fetchTimer

        interval: 500
        repeat: false
        onTriggered: githubService.isFetching = false
    }

    Timer {
        interval: 600000
        running: githubService.username !== ""
        repeat: true
        onTriggered: githubService.fetchData()
    }

}
