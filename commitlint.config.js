module.exports = {
  plugins: [
    {
      rules: {
        'subject-uppercase-start': ({ header, subject }) => [
          /^[A-Z]/.test(subject ?? header),
          'Subject must start with an uppercase letter',
        ],
      },
    },
  ],
  rules: {
    'subject-uppercase-start': [2, 'always'],
  },
};
