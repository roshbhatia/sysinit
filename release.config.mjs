export const analyzer = {
  parserOpts: {
    headerPattern: /^(\w+)(?:\((.*)\))?!?: (.*)$/,
    headerCorrespondence: ["type", "scope", "subject"],
    breakingHeaderPattern: /^(\w+)(?:\((.*)\))?!: (.*)$/,
    noteKeywords: ["BREAKING CHANGE", "BREAKING CHANGES"],
  },
  releaseRules: [
    { breaking: true, release: "major" },
    { type: "refactor", release: "patch" },
    { type: "build", release: "patch" },
    { type: "chore", release: "patch" },
    { type: "revert", release: "patch" },
  ],
};

export const notes = {
  parserOpts: analyzer.parserOpts,
  writerOpts: {
    transform(commit) {
      return {
        type: commit.type || "Other changes",
        scope: commit.scope === "*" ? "" : commit.scope,
        subject: commit.subject || commit.header,
        shortHash: commit.hash?.slice(0, 7),
        notes: commit.notes.map((note) => ({
          ...note,
          title: "BREAKING CHANGES",
        })),
      };
    },
  },
};

export default {
  branches: ["main"],
  tagFormat: "v${version}",
  repositoryUrl: "https://github.com/roshbhatia/sysinit.git",
  plugins: [
    ["@semantic-release/commit-analyzer", analyzer],
    ["@semantic-release/release-notes-generator", notes],
    [
      "@semantic-release/github",
      {
        successComment: false,
        failComment: false,
        failTitle: false,
        releasedLabels: false,
      },
    ],
  ],
};
