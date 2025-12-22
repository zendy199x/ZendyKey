# Contributing to ZendyKey

Thank you for considering contributing to ZendyKey! This document provides guidelines for contributing.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/zendy199x/ZendyKey/issues)
2. If not, create a new issue with:
   - Clear title describing the bug
   - macOS version
   - ZendyKey version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

### Suggesting Features

1. Check existing [Issues](https://github.com/zendy199x/ZendyKey/issues) and [Discussions](https://github.com/zendy199x/ZendyKey/discussions)
2. Create a new issue with:
   - Clear description of the feature
   - Use case / why it's useful
   - Any implementation ideas

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly on macOS 10.15+
5. Commit with clear messages
6. Push and create a Pull Request

## Development Setup

```bash
git clone https://github.com/your-username/ZendyKey.git
cd ZendyKey
./build_release.sh
```

## Code Style

- Follow Swift style guidelines
- Use descriptive variable names
- Add comments for complex logic
- All components use `ZK` prefix

## Testing

- Run unit tests before submitting PRs
- Test on multiple macOS versions if possible
- Test all input methods (Telex, VNI, VIQR)

## Questions?

Open a [Discussion](https://github.com/zendy199x/ZendyKey/discussions) for any questions.
