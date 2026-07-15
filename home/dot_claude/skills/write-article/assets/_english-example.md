---
title: "Passing An Argument To Docker Build Step In Azure Pipeline"
description: "It is easy to customize your Docker image with values. Here’s are the steps."
image: 2026-06-22-two-persons-exchanging-a-pieace-of-paper.jpg
imageAlt: Two persons exchanging a pieace of paper
date: 2026-06-22
categories:
  - Software Development
tags:
  - Docker
  - Microsoft Azure DevOps
  - Microsoft Azure
  - Python
---

Last year, [in this article](../../2025-08/configure-docker-image-in-azure-devops/index.md), I talked about splitting the build and push steps of a Docker image.

Today, I’ll provide an example of how I passed the version computed from an Azure DevOps variable into the application.

## Starting Point

In the previous article mentioned above, we learn how to split the build from the push step when using Docker in Azure.

Doing so allows to use to pass on arguments when build the Docker image. This can help perform many tasks, depending on what your needs are. But in this article, I’ll share one.

In my application, I have this module with a `GET `/version’ endpoint:

```python
import os

from flask import Blueprint, jsonify

version = Blueprint("version", __name__)

def get_version_from_file():
    version_file = os.path.join(os.path.dirname(__file__), 'version.txt')
    with open(version_file, 'r') as file:
        return file.read().strip()

@version.route("/", methods=["GET"])
def get_version():
    response = {
        "version": get_version_from_file()
    }
    return jsonify(response)
```

Given a text file `version.txt` placed in the module’s folder, querying `GET /version` would output the value stored into the text file.

Now, what are the steps to update so that the text file is filled with the new application version on each build?

## Modifying the Pipelines

### Evaluate the application version

That step works already. I invited to read the [”**Evaluate the Image Tag**” paragraph](../../2025-08/configure-docker-image-in-azure-devops/index.md#evaluate-the-image-tag) in the previous article.

We named the version evaluation step to `setVersionStep` and the actual version variable to `fullVersion`.

### Pass on the version to Docker Build Step

Since we split the build and push steps, we can use the `arguments` property on the build Docker command:

```yaml
- task: Docker@2
  displayName: Build image
  inputs:
    command: build
    repository: $(imageRepository)
    dockerfile: $(dockerfilePath)
    buildContext: $(projectPath)
    containerRegistry: $(dockerRegistryServiceConnection)
    tags: |
      $(imageTags)
    # The only change from the previous article.
    arguments: --build-arg VERSION=$(setVersionStep.fullVersion)
```

### Modify the Docker file

In the final step, we need to use the `VERSION` argument above in the `Dockerfile`.

First, let’s declare the argument:

```docker
ARG VERSION
```

Then, let’s print the value as a debug trace:

```docker
RUN echo "Version is <$VERSION>"
```

And finally, let’s write the version to that text file that the `GET /version` reads:

```docker
RUN echo $VERSION > /project-container/app/modules/version/version.txt
```

## Conclusion

That’s it! Now, you can pass on as many arguments as you need for your business logic.

If you liked this article…

{{< blockcontainer jli-notice-tip "Follow me">}}

Thanks for reading this article. Make sure to [follow me on X](https://x.com/LitzlerJeremie), [subscribe to my Substack publication](https://iamjeremie.substack.com/) and bookmark my blog to read more in the future.

{{< /blockcontainer >}}

Credit: Photo by RDNE Stock project on Pexels (`https://www.pexels.com/photo/shallow-focus-photo-of-students-cheating-during-an-exam-7092518/`).
