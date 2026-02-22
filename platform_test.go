package platform_test

import (
	"testing"

	"damiang78/go-platform"
)

func TestVersion(t *testing.T) {
	v := platform.Version()
	if v == "" {
		t.Fatal("Version() returned empty string")
	}
}
