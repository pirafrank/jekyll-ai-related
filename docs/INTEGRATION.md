# Jekyll integration

The plugin writes data; it does not modify layouts or posts. Add rendering logic to a layout or include.

## Default output

For `output_path: related_posts` and `post_unique_field: slug`, use:

```liquid
{% assign related = site.data.related_posts[page.slug] %}
{% if related %}
  <section class="related-posts">
    <h2>Related posts</h2>
    <ul>
      {% for item in related %}
        <li>
          <a href="{{ item.url | relative_url }}">{{ item.title }}</a>
          {% if item.similarity %}
            <span aria-label="similarity score">{{ item.similarity }}</span>
          {% endif %}
        </li>
      {% endfor %}
    </ul>
  </section>
{% endif %}
```

Results are ordered from highest similarity to lowest similarity. Each item normally contains:

```yaml
- title: Related post
  uid: related-post
  most_recent_edit: 2025-01-01T00:00:00+00:00
  url: /related-post/
  date: 2025-01-01 00:00:00 +0000
  similarity: 0.812
```

## Custom output path or identifier

If configuration uses:

```yaml
jekyll-ai-related:
  post_unique_field: uid
  output_path: ai/related
```

the lookup becomes `site.data.ai.related[page.uid]` and files are written below `_data/ai/related/`. The configured identifier must be present and unique for every processed post.

## Empty and stale results

The plugin writes only non-empty result sets. If a post no longer has qualifying related posts, an existing YAML file is not deleted automatically. Remove stale generated files as part of a cleanup step if that situation matters to the site.

The related data is generated outside a normal build, so a build can use the last successful output. This also means a post can be published before its related-post data has been regenerated.

