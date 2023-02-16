# frozen_string_literal: true

RSpec.describe "cloudformation" do
  it "fails with list on no default" do
    expect_any_instance_of(Lsaws::Lister).to receive(:_abort_with_list).and_call_original
    r, out, err = run("cloudformation")
    expect(r).to be_falsey
    expect(err).to eq("[!] no default entity type set for \"cloudformation\" SDK\n")
    expect(out).to eq("Known entity types are:\naccount_limits\nexports\nstack_events\nstack_sets\nstacks\ntype_registrations\ntype_versions\ntypes\n")
  end

  it "fails with list on undefined etype" do
    expect_any_instance_of(Lsaws::Lister).to receive(:_abort_with_list).and_call_original
    r, out, err = run("cloudformation foo")
    expect(r).to be_falsey
    expect(err).to eq("[!] \"cloudformation\" SDK does not have \"foo\" entity type\n")
    expect(out).to eq("Known entity types are:\naccount_limits\nexports\nstack_events\nstack_sets\nstacks\ntype_registrations\ntype_versions\ntypes\n")
  end

  it "lists available types" do
    l = run! "cloudformation -L"
    expect(l.strip.split).to eq(%w"account_limits exports stack_events stack_sets stacks type_registrations type_versions types")
  end
end
