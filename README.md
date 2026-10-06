<!--
Copyright (c) 2026 Joseph Hale
SPDX-License-Identifier: MPL-2.0
-->

<div align="center">

# Windows SSH Setup

Sign in to a Windows machine over ssh with the keys already on your GitHub
profile.

<!-- BADGES -->
[![License: MPL-2.0](https://badgen.net/github/license/thehale/windows-ssh-setup)](https://github.com/thehale/windows-ssh-setup/blob/main/LICENSE)
[![Sponsor thehale on GitHub](https://badgen.net/badge/icon/Sponsor/pink?icon=github&label)](https://github.com/sponsors/thehale)
[![Joseph Hale's software engineering blog](https://jhale.dev/badges/website.svg)](https://jhale.dev)
[![Follow Joseph Hale on LinkedIn](https://jhale.dev/badges/follow.svg)](https://www.linkedin.com/comm/mynetwork/discovery-see-all?usecase=PEOPLE_FOLLOWS&followMember=thehale)
</div>

## Quickstart

Run this in PowerShell on the Windows machine:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/thehale/windows-ssh-setup/main/windows-ssh-setup.ps1)))
```

It asks for your GitHub username, and for administrator approval when it needs
it.

## What you get

- The OpenSSH Server that ships with Windows, switched on to start with
  Windows. It accepts your GitHub keys, never passwords, and only from your
  local network.
- Sessions that open in Git Bash, so commands run as they would on a Mac or
  Linux machine.

Run it again after adding or revoking a key on GitHub, and the machine follows.

## License

Copyright (c) 2026 Joseph Hale, All Rights Reserved

Provided under the terms of the [Mozilla Public License, version 2.0](./LICENSE)

<details>

<summary><b>What does the MPL-2.0 license allow/require?</b></summary>

### TL;DR

You can use files from this project in both open source and proprietary
applications, provided you include the above attribution. However, if
you modify any code in this project, or copy blocks of it into your own
code, you must publicly share the resulting files (note, not your whole
program) under the MPL-2.0. The best way to do this is via a Pull
Request back into this project.

If you have any other questions, you may also find Mozilla's [official
FAQ](https://www.mozilla.org/en-US/MPL/2.0/FAQ/) for the MPL-2.0 license
insightful.

If you dislike this license, you can contact me about negotiating a paid
contract with different terms.

**Disclaimer:** This TL;DR is just a summary. All legal questions
regarding usage of this project must be handled according to the
official terms specified in the `LICENSE` file.

### Why the MPL-2.0 license?

I believe that an open-source software license should ensure that code
can be used everywhere.

Strict copyleft licenses, like the GPL family of licenses, fail to
fulfill that vision because they only permit code to be used in other
GPL-licensed projects. Permissive licenses, like the MIT and Apache
licenses, allow code to be used everywhere but fail to prevent
proprietary or GPL-licensed projects from limiting access to any
improvements they make.

In contrast, the MPL-2.0 license allows code to be used in any software
project, while ensuring that any improvements remain available for
everyone.

</details>
