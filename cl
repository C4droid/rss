#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
# Copyright © 2023 lennon
#
"""
rss for Project syndicate
"""
import arrow
from bs4 import BeautifulSoup
from mako.template import Template
import requests

headers = {
    "user-agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/112.0"
}

host = "https://cl.2076x.xyz/"

subscribes = [
    "thread0806.php?fid=7&search=667132",
    "thread0806.php?fid=7&search=112203",
    "thread0806.php?fid=7&search=660896",
    "thread0806.php?fid=7&search=661736",
    "thread0806.php?fid=7&search=558533",
    "thread0806.php?fid=7&search=639381",
    "thread0806.php?fid=7&search=421692",
]

RSS = Template(
    """<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>1024 新闻聚合</title>
  <link rel="alternate" type="text/html" href="https://github.com/c4droid/" />
  <link rel="self" type="application/atom+xml" href="https://raw.githubusercontent.com/C4droid/rss/main/1024.xml"/>
  <updated>2024-06-20T21:25:56+08:00</updated>
  <id>https://github.com/c4droid/rss/cl</id>
  <author>
     <name>linkong</name>
     <uri>http://github.com/c4droid</uri>
  </author>

%for e in entries:
  <entry>
    <title>${e.title}</title>
    <link href="${e.link}" />
    <id>${e.tid}</id>
    <published>${e.ctime}</published>
    <updated>${e.ctime}</updated>
    <summary type="text">${e.summary}</summary>
    <content type="text">${e.summary}</content>
  </entry>
%endfor
</feed>
"""
)


class Entry(object):
    def __init__(self):
        self.title = None
        self.ctime = None
        self.tid = None
        self.summary = None

    def __str__(self):
        return str(
            (
                self.ctime,
                self.title,
            )
        )


def get_root(url):
    response = requests.get(
        url,
        headers=headers,
        timeout=30,
    )
    return BeautifulSoup(response.text, "lxml")


def main():
    entries = []
    for e in subscribes:
        body = get_root(host + e)
        mark = (
            arrow.now()
            .replace(hour=0, minute=0, second=0, microsecond=0)
            .shift(days=-9)
        )
        for tr in body.select("#tbody>tr"):
            dt = arrow.get(
                tr.select("div.f12 span")[0]["data-timestamp"].replace("s", ""), "x"
            )
            if mark > dt:
                continue
            a_node = tr.select("h3 a")[0]
            a_url = host + a_node["href"]
            entry = Entry()
            entry.ctime = dt.format("YYYY-MM-DD HH:mm:ss")
            entry.tid = a_node["id"]
            entry.title = a_node.string
            entry.link = a_url
            entry.summary = a_node.string
            entries.append(entry)
    sorted_entries = sorted(entries, key=lambda x: x.ctime)
    with open("1024.xml", "w", encoding="utf8") as f:
        f.write(RSS.render(entries=sorted_entries))


if __name__ == "__main__":
    main()
