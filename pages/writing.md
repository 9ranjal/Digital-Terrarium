---
layout: default
title: Writing
permalink: /writing/
description: "Essays, short stories, and other creative writing."
---

<div class="page">
  <h1 class="page-heading">Writing</h1>

  <p>Essays, short stories, and other creative writing.</p>

  {%- assign writing_posts = site.posts | where: "categories", "writing" -%}

  {%- assign ss_posts = writing_posts | where: "subcategory", "short-stories" | sort: "date" | reverse -%}
  {%- assign ss_latest = ss_posts | first -%}
  {%- assign pp_posts = writing_posts | where: "subcategory", "101-philosophy-problems" | sort: "date" | reverse -%}
  {%- assign pp_latest = pp_posts | first -%}

  <ul class="post-list">
    <li>
      {% if ss_latest %}<span class="post-meta">{{ ss_latest.date | date: "%B %-d, %Y" }}</span>{% endif %}
      <a class="post-link" href="{{ '/writing/short-stories/' | relative_url }}">Short Stories</a>
    </li>
    <li>
      {% if pp_latest %}<span class="post-meta">{{ pp_latest.date | date: "%B %-d, %Y" }}</span>{% endif %}
      <a class="post-link" href="{{ '/writing/101-philosophy-problems/' | relative_url }}">101 Philosophy Problems</a>
    </li>
  </ul>

  {%- assign uncategorised = "" | split: "," -%}
  {%- for post in site.posts -%}
    {%- assign in_writing = false -%}
    {%- for c in post.categories -%}
      {%- if c == "writing" -%}
        {%- assign in_writing = true -%}
      {%- endif -%}
    {%- endfor -%}
    {%- if in_writing and post.subcategory == nil -%}
      {%- assign uncategorised = uncategorised | push: post -%}
    {%- endif -%}
  {%- endfor -%}

  {%- assign uncategorised = uncategorised | sort: "date" | reverse -%}

  {% if uncategorised.size > 0 %}
    <h2>Other</h2>
    <ul class="post-list">
      {% for post in uncategorised %}
        <li>
          <span class="post-meta">{{ post.date | date: "%B %-d, %Y" }}</span>
          <a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
        </li>
      {% endfor %}
    </ul>
  {% endif %}
</div>
