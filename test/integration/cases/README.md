This directory contains full integration tests comparing the output from Liquex and the
Liquid gem. Tests are stored as [HRX](https://github.com/google/hrx) files to help keep
the JSON file and liquid file together.  One JSON file and one liquid file must be included
in each of the integration test cases.

All HRX files are executed automatically and any differing results will show up in the
test suite.

To run these tests, you must install the liquid gem:

`gem install liquid`

Then you can run the integration tests manually:

`mix test test/integration/comparison_test.exs`