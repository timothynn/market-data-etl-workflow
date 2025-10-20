# Contributing to n8n Workflow Starter

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🤝 How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/YOUR_USERNAME/n8n-workflow-starter/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version, etc.)
   - Logs if applicable

### Suggesting Features

1. Check existing [Feature Requests](https://github.com/YOUR_USERNAME/n8n-workflow-starter/issues?q=is%3Aissue+label%3Aenhancement)
2. Create a new issue with:
   - Clear use case description
   - Expected behavior
   - Why this would be useful
   - Potential implementation approach

### Contributing Workflows

We love workflow contributions! To add a workflow:

1. **Create the workflow** in your n8n instance
2. **Export it** as JSON
3. **Add documentation** explaining:
   - What the workflow does
   - Required credentials/nodes
   - Configuration steps
   - Use cases
4. **Test thoroughly** before submitting
5. **Submit a PR** with the workflow in `workflows/examples/`

#### Workflow Guidelines

- Use clear, descriptive names
- Add comments for complex logic
- Include error handling
- Document all required credentials
- Test with sample data
- Keep it modular and reusable

### Pull Request Process

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/n8n-workflow-starter.git
   cd n8n-workflow-starter
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow existing code style
   - Test your changes
   - Update documentation

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add amazing feature"
   ```

   Use [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation
   - `chore:` - Maintenance
   - `refactor:` - Code refactoring
   - `test:` - Tests

4. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then open a PR on GitHub

5. **PR Requirements**
   - Clear title and description
   - Reference related issues
   - Pass all CI checks
   - Update CHANGELOG.md
   - Add tests if applicable

## 📝 Code Style

### Shell Scripts
- Use `#!/bin/bash` shebang
- Include error handling (`set -e`)
- Add comments for complex logic
- Use descriptive variable names
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Docker
- Use official base images
- Minimize layers
- Use multi-stage builds when possible
- Don't run as root
- Use .dockerignore

### Documentation
- Use clear, simple language
- Include code examples
- Keep README.md up to date
- Add screenshots for UI features

## 🧪 Testing

Before submitting:

1. **Test locally**
   ```bash
   docker compose up -d
   ./scripts/backup.sh
   ./scripts/restore.sh backups/latest.tar.gz
   ```

2. **Validate configuration**
   ```bash
   docker compose config
   ```

3. **Check logs**
   ```bash
   docker compose logs
   ```

4. **Test workflows**
   - Import your workflow
   - Test with sample data
   - Verify error handling

## 🔐 Security

- **Never commit credentials** or secrets
- Use `.env` for sensitive data
- Follow security best practices
- Report security issues privately to maintainers

## 📋 Checklist

Before submitting a PR, ensure:

- [ ] Code follows project style
- [ ] Documentation is updated
- [ ] Tests pass locally
- [ ] Commits follow convention
- [ ] No sensitive data in code
- [ ] CHANGELOG.md updated
- [ ] PR description is clear

## 🎯 Priority Areas

We especially welcome contributions in:

- **Workflow templates** - More examples!
- **Documentation** - Tutorials, guides
- **Scripts** - Automation tools
- **Testing** - CI/CD improvements
- **Performance** - Optimization
- **Security** - Best practices

## 💬 Communication

- **Questions**: Open a [Discussion](https://github.com/YOUR_USERNAME/n8n-workflow-starter/discussions)
- **Bugs**: Create an [Issue](https://github.com/YOUR_USERNAME/n8n-workflow-starter/issues)
- **Ideas**: Start a [Discussion](https://github.com/YOUR_USERNAME/n8n-workflow-starter/discussions)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

Thank you for making this project better! 🎉
