package usage

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestReadDirSelectsOnlyYmlFiles(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{"20.resources.yml", "10.yml", "resources.yml.bak", "resources.yml~", "resources.yaml", "notes.txt"} {
		if err := os.WriteFile(filepath.Join(dir, name), nil, 0600); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.Mkdir(filepath.Join(dir, "directory.yml"), 0700); err != nil {
		t.Fatal(err)
	}
	want := []string{"10.yml", "20.resources.yml"}
	if got := ReadDir(dir); !reflect.DeepEqual(got, want) {
		t.Fatalf("ReadDir() = %v, want %v", got, want)
	}
}

func TestReadDirIgnoresBackupOnlyDirectory(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "resources.yml.bak"), nil, 0600); err != nil {
		t.Fatal(err)
	}
	if got := ReadDir(dir); len(got) != 0 {
		t.Fatalf("ReadDir() = %v, want no usage files", got)
	}
}
