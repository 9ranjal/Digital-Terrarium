---
layout: default
title: Short Stories and Essays
permalink: /writing/short-stories/
---

<div class="page subcategory-page">
  <h1 class="page-heading">{{ page.title }}</h1>

  {%- assign all_posts = site.posts | where: "subcategory", "short-stories" | sort: "date" | reverse -%}

  {%- assign ss_posts = "" | split: "," -%}
  {%- assign essay_posts = "" | split: "," -%}

  {%- for post in all_posts -%}
    {%- if post.tags contains "essays" -%}
      {%- assign essay_posts = essay_posts | push: post -%}
    {%- else -%}
      {%- assign ss_posts = ss_posts | push: post -%}
    {%- endif -%}
  {%- endfor -%}

  <div class="two-col-writing">
    <div class="writing-col">
      <h2 class="writing-col-heading">Short Stories</h2>
      {% if ss_posts.size > 0 %}
        <ul class="post-list">
          {% for post in ss_posts %}
            <li>
              <span class="post-meta">{{ post.date | date: "%d/%m/%y" }}</span>
              <a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
            </li>
          {% endfor %}
        </ul>
      {% else %}
        <p>No posts yet.</p>
      {% endif %}
    </div>

    <div class="writing-col">
      <h2 class="writing-col-heading">Essays</h2>
      {% if essay_posts.size > 0 %}
        <ul class="post-list">
          {% for post in essay_posts %}
            <li>
              <span class="post-meta">{{ post.date | date: "%d/%m/%y" }}</span>
              <a class="post-link" href="{{ post.url | relative_url }}">{{ post.title | escape }}</a>
            </li>
          {% endfor %}
        </ul>
      {% else %}
        <p>No posts yet.</p>
      {% endif %}
    </div>
  </div>
</div>
